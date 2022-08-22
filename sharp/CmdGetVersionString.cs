using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace CCModManager {
    class Package {
        public string version { get; set; }
    }

    public class CmdGetVersionString : Cmd<string, string> {

        public override bool Taskable => true;

        public override string Run(string root) {
            Tuple<string, Version, Version> data = GetVersion(root);
            return data.Item1;
        }

        public static Tuple<string, Version, Version> GetVersion(string root) {
            if (File.Exists(Path.Combine(root, "Celeste.exe")) &&
                File.Exists(Path.Combine(root, "AppxManifest.xml")) &&
                File.Exists(Path.Combine(root, "xboxservices.config"))) {
                try {
                    using (File.Open(Path.Combine(root, "Celeste.exe"), FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete)) {
                        // no-op, just try to see if the file can be opened at all.
                    }
                } catch {
                    return new Tuple<string, Version, Version>("Unsupported version of Celeste.", null, null);
                }
            }

            try
            {
                Package packageJson;
                using (StreamReader reader = new StreamReader(Path.Combine(root, "package.json")))
                using (JsonTextReader json = new JsonTextReader(reader))
                {
                    packageJson = JsonSerializer.Create().Deserialize(json, typeof(Package)) as Package;
                }

                string versionString = packageJson.version;
                List<int> versionInts = new List<int>();
                foreach (var num in versionString.Split('.'))
                {
                    versionInts.Add(Int32.Parse(num));
                }

                Version version = new Version();
                if (versionInts == null || versionInts.Count == 0)
                    version = new Version();
                else if (versionInts.Count == 2)
                    version = new Version(versionInts[0], versionInts[1]);
                else if (versionInts.Count == 3)
                    version = new Version(versionInts[0], versionInts[1], versionInts[2]);
                else if (versionInts.Count == 4)
                    version = new Version(versionInts[0], versionInts[1], versionInts[2], versionInts[3]);

                string status = $"CrossCode {version}";

                // TODO: Detect CCLoader installation

                return new Tuple<string, Version, Version>(status, null, null);
            } catch (Exception e) {
                return new Tuple<string, Version, Version>($"? - {e.Message}", null, null);
            }
        }

    }
}
