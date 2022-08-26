using System.Collections;
using System.IO;
using System.IO.Compression;

namespace CCModManager;

public unsafe partial class CmdInstallCCLoader : Cmd<string, string, string, IEnumerator> 
{

	public override IEnumerator Run(string root, string artifactBase, string sha)
	{
		var PathOrig = Path.Combine(root, "orig");

		// if (artifactBase.StartsWith("file://")) {
		// artifactBase = artifactBase.Substring("file://".Length);
		// yield return Status($"Unzipping {Path.GetFileName(artifactBase)}", false, "download", false);
		//
		// using (FileStream wrapStream = File.Open(artifactBase, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
		// using (ZipArchive wrap = new ZipArchive(wrapStream, ZipArchiveMode.Read)) {
		//     ZipArchiveEntry zipEntry = wrap.GetEntry("nested-zip.zip");
		//     if (zipEntry == null) {
		//         yield return Unpack(wrap, root, "main/");
		//     } else {
		//         using (Stream zipStream = zipEntry.Open())
		//         using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read))
		//             yield return Unpack(zip, root);
		//     }
		// }

		if (!Directory.Exists(PathOrig))
		{
			yield return Status("Creating backup orig directory", false, "backup", false);
			Directory.CreateDirectory(PathOrig);
		}
			
		var toBackup = new[] { "package.json" };
		for (var i = 0; i < toBackup.Length; i++)
		{
			yield return Status($"Backing up {toBackup.Length} files", 0f, "backup", false);
			var from = Path.Combine(root,     "package.json");
			var to   = Path.Combine(PathOrig, Path.GetFileName(from));
			if (!File.Exists(from) || File.Exists(to)) continue;

			yield return Status($"Backing up {from} => {to}", i / (float) toBackup.Length, "backup", true);
			File.Copy(from, to);
		}

		yield return Status("Downloading CCLoader", false, "download", false);

		using var zipStream = new MemoryStream();
		yield return Download(artifactBase, 0, zipStream);

		yield return Status("Unzipping CCLoader", false, "download", false);
		zipStream.Seek(0, SeekOrigin.Begin);
		using var zip = new ZipArchive(zipStream, ZipArchiveMode.Read);
		yield return Status(zip.ToString()!, false, "download", false);
		yield return Unpack(zip, root, $"CCDirectLink-CCLoader-{sha}/");
	}
}