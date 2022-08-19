using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace Olympus {
    public unsafe class CmdStatus : Cmd<string, object[]> {
        public override bool LogRun => false;
        public override object[] Run(string id) {
            CmdTask task = CmdTasks.Get(id);
            if (task == null)
                return new object[0];
            return new object[] { task.Status, task.Queue.Count };
        }
    }
}
