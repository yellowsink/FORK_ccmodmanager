using System.IO;
using MonoMod.Cil;

namespace CCModManager
{
    public unsafe class CmdRmDir : Cmd<string, string>
    {
        public override string Run(string dir)
        {
            try
            {
                Directory.Delete(dir, true);
            }
            catch
            {
                return "failed";
            }

            return null;
        }
    }
}