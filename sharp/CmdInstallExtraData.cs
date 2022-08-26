using System;
using System.Collections;
using System.IO;

namespace CCModManager;

public unsafe class CmdInstallExtraData : Cmd<string, string, IEnumerator> {

	public override IEnumerator Run(string url, string path) {
		var resPath = Path.Combine(Program.RootDirectory!, path);
		if (!resPath.StartsWith(Program.RootDirectory!)) {
			yield return Status("Invalid path.", 1f, "error", false);
			throw new Exception($"Invalid path: {path}");
		}

		if (File.Exists(resPath)) {
			yield return Status($"Deleting existing {resPath}", false, "", false);
			File.Delete(resPath);
		}

		yield return Status($"Downloading {url} to {resPath}", false, "download", false);
		var tmp = resPath + ".part";
		if (File.Exists(tmp))
			File.Delete(tmp);
		using var stream = File.Open(tmp, FileMode.Create, FileAccess.ReadWrite, FileShare.None);
		yield return Download(url, 0, stream);
		File.Move(tmp, resPath);
	}

}