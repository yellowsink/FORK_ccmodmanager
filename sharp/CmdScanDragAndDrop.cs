using System;
using System.IO;
using System.IO.Compression;

namespace CCModManager;

public class CmdScanDragAndDrop : Cmd<string, string> {
	public override string Run(string path) {
		if (path.EndsWith(".zip")) {
			try {
				using (var stream = File.Open(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
				using (var zip = new ZipArchive(stream, ZipArchiveMode.Read)) {
					// TODO: Write better detection of mod vs. ccloader
					if (zip.GetEntry("ccmod.json") != null || zip.GetEntry("package.json") != null)
						return "mod";

					if (zip.GetEntry("something-ccloader-specific") != null /* ??? */)
						return "ccloader";
				}
			} catch (Exception e) {
				Console.Error.WriteLine($"ZIP cannot be scanned: {path}");
				Console.Error.WriteLine(e);
			}
		}

		return "unknown";
	}
}