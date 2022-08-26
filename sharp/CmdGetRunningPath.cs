using System;
using MonoMod.Utils;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace CCModManager;

public class CmdGetRunningPath : Cmd<string, string, string?> {

	public override bool Taskable => true;

	public override string? Run(string root, string procname) {
		procname = procname.ToLowerInvariant();

		if (PlatformHelper.Is(Platform.Unix)) {
			// macOS lacks procfs and this sucks but oh well.
			// FIXME: This can hang on some macOS machines, but running ps in terminal works?! Further debugging required!
			if (PlatformHelper.Is(Platform.MacOS))
				return null;

			var path = ProcessHelper.ReadTimeout("ps", "-wweo args", 1000, out _)
									.Split('\n', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries)
									.FirstOrDefault(p => (string.IsNullOrEmpty(root) || p.Contains(root))
													  && p.ToLowerInvariant().Contains(procname))
								   ?.Trim();

			if (string.IsNullOrEmpty(path))
				return null;

			var indexOfCrossCode = path.ToLowerInvariant().IndexOf(procname, StringComparison.Ordinal);
			var indexOfEnd       = path.LastIndexOf(Path.DirectorySeparatorChar, indexOfCrossCode);
			if (indexOfEnd < 0)
				indexOfEnd = path.Length;
			return path[..indexOfEnd];
		}

		var procSuffix = Path.DirectorySeparatorChar + procname + ".exe";
		try {
			foreach (var p in Process.GetProcesses()) {
				try {
					if (!p.ProcessName.ToLowerInvariant().Contains(procname))
						continue;
					var path = p.MainModule?.FileName;
					if (!string.IsNullOrEmpty(path)                         &&
						(string.IsNullOrEmpty(root) || path.Contains(root)) &&
						path.ToLowerInvariant().EndsWith(procSuffix)        &&
						(path = path[..^procSuffix.Length]).ToLowerInvariant().Contains(procname)) {
						return path;
					}
				}
				catch
				{ // ignored
				}
				finally {
					try {
						p.Dispose();
					}
					catch
					{ // ignored
					}
				}
			}
		}
		catch
		{ // ignored
		}

		return null;
	}

}