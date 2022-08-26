using System;
using System.Collections;
using System.IO;

namespace CCModManager;

public unsafe class CmdUninstallCCLoader : Cmd<string, string, IEnumerator> {

	public override IEnumerator Run(string root, string artifactBase) {
		yield return Status("Uninstalling CCLoader", false, "backup", false);

		var origDir = Path.Combine(root, "orig");
		if (!Directory.Exists(origDir)) {
			yield return Status("Backup (orig) folder not found", 1f, "error", false);
			throw new Exception($"Backup folder not found: {origDir}");
		}

		var origs = Directory.GetFiles(origDir);

		yield return Status($"Reverting {origs.Length} files", 0f, "backup", false);

		for (var i = 0; i < origs.Length; i++)
		{
			var orig = origs[i];
			
			var name = Path.GetFileName(orig);
			yield return Status($"Reverting #{i} / {origs.Length}: {name}", i / (float) origs.Length, "backup", true);

			var to       = Path.Combine(root, name);
			var toParent = Path.GetDirectoryName(to);
			Console.Error.WriteLine($"{orig} -> {to}");

			if (!Directory.Exists(toParent))
				Directory.CreateDirectory(toParent!);

			if (File.Exists(to))
				File.Delete(to);

			File.Copy(orig, to);
		}

		yield return Status($"Reverted {origs.Length} files", 1f, "done", true);

		if (Directory.Exists(Path.Combine(root, "ccloader")))
		{
			yield return Status("Deleting CCLoader", 0f, "monomod", false);
			Directory.Delete(Path.Combine(root, "ccloader"), true);
			yield return Status("Deleted CCLoader", 1f, "monomod", true);
		}
	}

}