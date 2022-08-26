using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CCModManager {
    public class CmdScanDragAndDrop : Cmd<string, string> {
        public override string Run(string path) {
            if (path.EndsWith(".zip")) {
                try {
                    using (FileStream stream = File.Open(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                    using (ZipArchive zip = new ZipArchive(stream, ZipArchiveMode.Read)) {
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
}