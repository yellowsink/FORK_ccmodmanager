using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json;
using YYProject.XXHash;

namespace CCModManager {
    class CCMod
    {
        public string title { get; set; }
        public string name { get; set; }
        public string version { get; set; }
    }
    public unsafe class CmdModList : Cmd<string, IEnumerator> {
        public override IEnumerator Run(string root) {
            root = Path.Combine(root, "assets", "mods");
            if (!Directory.Exists(root))
                yield break;

            string[] files = Directory.GetFiles(root);
            for (int i = 0; i < files.Length; i++) {
                string file = files[i];
                Console.Error.WriteLine($"[sharp] Checking {file}");
                if (!file.EndsWith(".ccmod"))
                    continue;

                Console.Error.WriteLine($"[sharp] CCMod found: {file}");

                ModInfo info = new ModInfo
                {
                    Path = file,
                    IsZIP = true
                };

                using (FileStream zipStream = File.Open(file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete)) {
                    zipStream.Seek(0, SeekOrigin.Begin);

                    using (ZipArchive zip = new ZipArchive(zipStream, ZipArchiveMode.Read))
                    using (Stream stream = (zip.GetEntry("ccmod.json") ?? zip.GetEntry("package.json"))?.Open())
                    using (StreamReader reader = stream == null ? null : new StreamReader(stream))
                        info.Parse(reader, reader == null);
                }

                Console.Error.WriteLine($"[sharp] ModInfo for {file}: {info}");

                yield return info;
            }

            files = Directory.GetDirectories(root);
            for (int i = 0; i < files.Length; i++) {
                string file = files[i];
                string name = Path.GetFileName(file);
                Console.Error.WriteLine($"[sharp] Checking {name}");

                ModInfo info = new ModInfo
                {
                    Path = file,
                    IsZIP = false
                };

                if (name == "simplify" || name == "ccloader-version-display")
                    info.IsCore = true;

                Console.Error.WriteLine($"[sharp] {(info.IsCore ? "Core " : "")}Mod found {name}");

                try {
                    string jsonPath = Path.Combine(file, "ccmod.json");
                    if (!File.Exists(jsonPath))
                        jsonPath = Path.Combine(file, "package.json");

                    if (File.Exists(jsonPath)) {
                        using (FileStream stream = File.Open(jsonPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                        using (StreamReader reader = new StreamReader(stream))
                            info.Parse(reader);
                    }
                } catch (UnauthorizedAccessException) {
                }

                Console.Error.WriteLine($"[sharp] ModInfo for {name}: {info}");

                yield return info;
            }
        }

        public class ModInfo {
            public string Path;
            public string Hash;
            public bool IsZIP;
            public bool IsCore;

            public string Name;
            public string Version;
            public bool IsValid;

            public void Parse(TextReader reader, bool error = false) {
                if (error)
                {
                    Name = "This CCMod was packaged incorrectly.";
                }
                else
                {
                    using (JsonTextReader json = new JsonTextReader(reader))
                    {
                        CCMod ccmod = JsonSerializer.Create().Deserialize(json, typeof(CCMod)) as CCMod;
                        Console.Error.WriteLine($"[sharp] Parsing mod: {ccmod}");
                        Name = ccmod.name ?? ccmod.title;
                        Version = ccmod.version;
                    }
                }

            }
        }

    }
}