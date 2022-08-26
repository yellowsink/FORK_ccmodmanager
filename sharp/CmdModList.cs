using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.IO.Compression;
using System.Text.Json;

namespace CCModManager;

[SuppressMessage("ReSharper", "InconsistentNaming")]
internal record CCMod(string? title, string? name, string version);
	
public unsafe class CmdModList : Cmd<string, IEnumerator<CmdModList.ModInfo>> {
	public override IEnumerator<ModInfo> Run(string root) {
		root = Path.Combine(root, "assets", "mods");
		if (!Directory.Exists(root))
			yield break;

		foreach (var file in Directory.GetFiles(root))
		{
			Console.Error.WriteLine($"[sharp] Checking {file}");
			if (!file.EndsWith(".ccmod"))
				continue;

			Console.Error.WriteLine($"[sharp] CCMod found: {file}");

			var info = new ModInfo
			{
				Path  = file,
				IsZIP = true
			};

			using var zipStream = File.Open(file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete);
			zipStream.Seek(0, SeekOrigin.Begin);

			using var zip    = new ZipArchive(zipStream, ZipArchiveMode.Read);
			using var stream = (zip.GetEntry("ccmod.json") ?? zip.GetEntry("package.json"))?.Open();
			using var reader = stream == null ? null : new StreamReader(stream);
			info.Parse(reader?.ReadToEnd()!, reader == null);

			Console.Error.WriteLine($"[sharp] ModInfo for {file}: {info}");

			yield return info;
		}

		foreach (var file in Directory.GetDirectories(root))
		{
			var name = Path.GetFileName(file);
			Console.Error.WriteLine($"[sharp] Checking {name}");

			var info = new ModInfo
			{
				Path  = file,
				IsZIP = false
			};

			if (name is "simplify" or "ccloader-version-display")
				info.IsCore = true;

			Console.Error.WriteLine($"[sharp] {(info.IsCore ? "Core " : "")}Mod found {name}");

			try {
				var jsonPath = Path.Combine(file, "ccmod.json");
				if (!File.Exists(jsonPath))
					jsonPath = Path.Combine(file, "package.json");

				if (File.Exists(jsonPath)) info.Parse(File.ReadAllText(jsonPath));
			} catch (UnauthorizedAccessException) {
			}

			Console.Error.WriteLine($"[sharp] ModInfo for {name}: {info}");

			yield return info;
		}
	}

	public class ModInfo {
		public string? Path;
		public string? Hash;
		// ReSharper disable once InconsistentNaming
		public bool    IsZIP;
		public bool    IsCore;

		public string? Name;
		public string? Version;
		public bool    IsValid;

		public void Parse(string json, bool error = false) {
			if (error)
			{
				Name = "This CCMod was packaged incorrectly.";
			}
			else
			{
				var ccMod = JsonSerializer.Deserialize<CCMod>(json);
				Console.Error.WriteLine($"[sharp] Parsing mod: {ccMod}");
				Name    = ccMod?.name ?? ccMod?.title;
				Version = ccMod?.version;
			}

		}
	}

}