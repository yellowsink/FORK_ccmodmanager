using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;

namespace CCModManager;

public static /*partial*/ class Cmds {
	private static readonly Dictionary<string, Cmd> All       = new();
	private static readonly Dictionary<Type, Cmd>   AllByType = new();

	public static void Init() {
		foreach (var type in typeof(Cmd).Assembly.GetTypes()) {
			if (!typeof(Cmd).IsAssignableFrom(type) || type.IsAbstract)
				continue;

			var cmd = (Cmd) Activator.CreateInstance(type)!;
			All[cmd.ID.ToLowerInvariant()] = cmd;
			AllByType[type]                = cmd;
		}
	}

	public static Cmd? Get(string id)
		=> All.TryGetValue(id, out var cmd) ? cmd : null;

/*
        public static T? Get<T>(string id) where T : Cmd
            => All.TryGetValue(id, out var cmd) ? (T) cmd : null;
*/

	public static T? Get<T>() where T : Cmd
		=> AllByType.TryGetValue(typeof(T), out var cmd) ? (T) cmd : null;
}

public abstract class Cmd {
	public virtual  string ID         => GetType().Name[3..];
	public abstract Type?  InputType  { get; }
	public abstract Type   OutputType { get; }
	public virtual  bool   LogRun     => true;
	public virtual  bool   Taskable   => false;
	public abstract object? Run(object input);
	public static object[] Status(string text, float progress, string shape, bool update) {
		Console.Error.WriteLine(text);
		return StatusSilent(text, progress, shape, update);
	}

	public static object[] Status(string text, bool progress, string shape, bool update) {
		Console.Error.WriteLine(text);
		return StatusSilent(text, progress, shape, update);
	}

	private static object[] StatusSilent(string text, float progress, string shape, bool update) {
		if (update)
			CmdTask.Update++;
		return new object[] { text, progress, shape, update };
	}

	private static object[] StatusSilent(string text, bool progress, string shape, bool update) {
		if (update)
			CmdTask.Update++;
		return new object[] { text, progress, shape, update };
	}


/*
	public static IEnumerator Try(IEnumerator inner, Exception[] ea) {
		while (true)
		{
			try
			{
				if (!inner.MoveNext())
					yield break;
			} catch (Exception e)
			{
				ea[0] = e;
				yield break;
			}
			yield return inner.Current;
		}
	}
*/


	public static IEnumerator<object> Download(string url, long length, Stream copy) {

		yield return Status($"Downloading {Path.GetFileName(url)}", false, "download", false);

		yield return Status("", false, "download", false);

		var timeStart = DateTime.Now;
		var pos       = 0;

		using var hc = new HttpClient();
		hc.Timeout = new TimeSpan(0, 0, 0, 10); // 10 seconds
		hc.DefaultRequestHeaders.Add("User-Agent", "CCDirectLink.CCModManager.Sharp");
		var resp = hc.Send(new HttpRequestMessage(HttpMethod.Get, url));
			
		using var input = resp.Content.ReadAsStream();
			
		if (length == 0) {
			//if (input.CanSeek) {
			// Mono
			length = input.Length;
			/*} else {
				// .NET
				try {
					HttpWebRequest reqHEAD = (HttpWebRequest) WebRequest.Create(url);
					reqHEAD.Method = "HEAD";
					using (HttpWebResponse resHEAD = (HttpWebResponse) reqHEAD.GetResponse())
						length = resHEAD.ContentLength;
				} catch (Exception) {
					length = 0;
				}
			}*/
		}

		var progressSize  = length;
		var progressScale = 1;
		while (progressSize > int.MaxValue) {
			progressScale *= 10;
			progressSize  =  length / progressScale;
		}

		var timeLast = timeStart;

		var buffer = new byte[4096];
		int read;
		var readForSpeed = 0;
		var speed        = 0;
		do {
			read  = input.Read(buffer, 0, buffer.Length);
			copy.Write(buffer, 0, read);
			pos          += read;
			readForSpeed += read;

			var td = DateTime.Now - timeLast;
			if (td.TotalMilliseconds > 100) {
				speed        = (int) ((readForSpeed / 1024D) / td.TotalSeconds);
				readForSpeed = 0;
				timeLast     = DateTime.Now;
			}

			if (length > 0) {
				yield return StatusSilent($"Downloading: {((int) Math.Floor(100D * Math.Min(1D, pos / (double) length)))}% @ {speed} KiB/s", (float) ((pos / progressScale) / (double) progressSize), "download", true);
			} else {
				yield return StatusSilent($"Downloading: {((int) Math.Floor(pos / 1000D))}KiB @ {speed} KiB/s", false, "download", true);
			}
		} while (read > 0);

		var logTime = (DateTime.Now - timeStart).TotalSeconds.ToString(CultureInfo.InvariantCulture);
		logTime = logTime[..Math.Min(logTime.IndexOf('.') + 3, logTime.Length)];
		yield return Status($"Downloaded {pos} bytes in {logTime} seconds.", 1f, "download", true);
	}


	public static IEnumerator Unpack(ZipArchive zip, string root, string prefix = "") {
		var count = string.IsNullOrEmpty(prefix) ? zip.Entries.Count : zip.Entries.Count(entry => entry.FullName.StartsWith(prefix));

		yield return Status($"Unzipping {count} files", 0f, "download", false);

		for (var i = 0; i < zip.Entries.Count; i++)
		{
			var entry = zip.Entries[i];
			
			var name  = entry.FullName;
			if (string.IsNullOrEmpty(name) || name.EndsWith("/"))
				continue;

			if (!string.IsNullOrEmpty(prefix))
			{
				if (!name.StartsWith(prefix))
					continue;
				name = name[prefix.Length..];
			}

			yield return Status($"Unzipping #{i} / {count}: {name}", i / (float) count, "download", true);

			var to       = Path.Combine(root, name);
			var toParent = Path.GetDirectoryName(to);
			Console.Error.WriteLine($"{name} -> {to}");

			if (!Directory.Exists(toParent))
				Directory.CreateDirectory(toParent!);

			if (File.Exists(to))
				File.Delete(to);

			using var fs         = File.OpenWrite(to);
			using var compressed = entry.Open();
			compressed.CopyTo(fs);
		}

		yield return Status($"Unzipped {count} files", 1f, "download", true);
	}

}

public abstract class Cmd<TOutput> : Cmd {
	public override Type?   InputType         => null;
	public override Type    OutputType        => typeof(TOutput);
	public override object? Run(object input) => Run();
	public abstract TOutput Run();
}

public abstract class Cmd<TIn, TOut> : Cmd {
	public override Type InputType  => typeof(Tuple<TIn>);
	public override Type  OutputType => typeof(TOut);
	public override object? Run(object input)
	{
		return Run(((Tuple<TIn>) input).Item1);
	}
	public abstract TOut Run(TIn input);
}

public abstract class Cmd<TIn1, TIn2, TOut> : Cmd {
	public override Type InputType  => typeof(Tuple<TIn1, TIn2>);
	public override Type  OutputType => typeof(TOut);
	public override object? Run(object input) {
		var (i1, i2) = (Tuple<TIn1, TIn2>) input;
		return Run(i1, i2);
	}
	public abstract TOut Run(TIn1 input1, TIn2 input2);
}

public abstract class Cmd<TIn1, TIn2, TIn3, TOut> : Cmd {
	public override Type InputType  => typeof(Tuple<TIn1, TIn2, TIn3>);
	public override Type  OutputType => typeof(TOut);
	public override object? Run(object input) {
		var (i1, i2, i3) = (Tuple<TIn1, TIn2, TIn3>) input;
		return Run(i1, i2, i3);
	}
	public abstract TOut Run(TIn1 input1, TIn2 input2, TIn3 input3);
}

public abstract class Cmd<TIn1, TIn2, TIn3, TIn4, TOut> : Cmd {
	public override Type InputType  => typeof(Tuple<TIn1, TIn2, TIn3, TIn4>);
	public override Type  OutputType => typeof(TOut);
	public override object? Run(object input) {
		var (i1, i2, i3, i4) = (Tuple<TIn1, TIn2, TIn3, TIn4>) input;
		return Run(i1, i2, i3, i4);
	}
	public abstract TOut Run(TIn1 input1, TIn2 input2, TIn3 input3, TIn4 input4);
}

public abstract class Cmd<TIn1, TIn2, TIn3, TIn4, TIn5, TOut> : Cmd {
	public override Type InputType  => typeof(Tuple<TIn1, TIn2, TIn3, TIn4, TIn5>);
	public override Type  OutputType => typeof(TOut);
	public override object? Run(object input) {
		var (i1, i2, i3, i4, i5) = (Tuple<TIn1, TIn2, TIn3, TIn4, TIn5>) input;
		return Run(i1, i2, i3, i4, i5);
	}
	public abstract TOut Run(TIn1 input1, TIn2 input2, TIn3 input3, TIn4 input4, TIn5 input5);
}

public abstract class Cmd<TIn1, TIn2, TIn3, TIn4, TIn5, TIn6, TOut> : Cmd {
	public override Type InputType  => typeof(Tuple<TIn1, TIn2, TIn3, TIn4, TIn5, TIn6>);
	public override Type  OutputType => typeof(TOut);
	public override object? Run(object input) {
		var (i1, i2, i3, i4, i5, i6) = (Tuple<TIn1, TIn2, TIn3, TIn4, TIn5, TIn6>) input;
		return Run(i1, i2, i3, i4, i5, i6);
	}
	public abstract TOut Run(TIn1 input1, TIn2 input2, TIn3 input3, TIn4 input4, TIn5 input5, TIn6 input6);
}

public abstract class Cmd<TIn1, TIn2, TIn3, TIn4, TIn5, TIn6, TIn7, TOut> : Cmd {
	public override Type InputType  => typeof(Tuple<TIn1, TIn2, TIn3, TIn4, TIn5, TIn6, TIn7>);
	public override Type  OutputType => typeof(TOut);
	public override object? Run(object input) {
		var (i1, i2, i3, i4, i5, i6, i7) = (Tuple<TIn1, TIn2, TIn3, TIn4, TIn5, TIn6, TIn7>) input;
		return Run(i1, i2, i3, i4, i5, i6, i7);
	}
	public abstract TOut Run(TIn1 input1, TIn2 input2, TIn3 input3, TIn4 input4, TIn5 input5, TIn6 input6, TIn7 input7);
}

public abstract class Cmd<TIn1, TIn2, TIn3, TIn4, TIn5, TIn6, TIn7, TIn8, TOut> : Cmd {
	public override Type InputType => typeof(Tuple<TIn1, TIn2, TIn3, TIn4, TIn5, TIn6, TIn7, Tuple<TIn8>>);
	public override Type OutputType => typeof(TOut);
	public override object? Run(object input) {
		var (i1, i2, i3, i4, i5, i6, i7, i8) = (Tuple<TIn1, TIn2, TIn3, TIn4, TIn5, TIn6, TIn7, Tuple<TIn8>>) input;
		return Run(i1, i2, i3, i4, i5, i6, i7, i8);
	}
	public abstract TOut Run(TIn1 input1, TIn2 input2, TIn3 input3, TIn4 input4, TIn5 input5, TIn6 input6, TIn7 input7, TIn8 input8);
}