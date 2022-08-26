using System.Collections.Generic;
using System.Threading;

namespace CCModManager;

public unsafe class CmdDummyTask : Cmd<int, int, IEnumerator<object[]>> {

	public override IEnumerator<object[]> Run(int count, int sleep) {
		for (var i = 0; i <= count; i++) {
			yield return Status("Test #" + i, i / (float) count, "", false);
			Thread.Sleep(sleep);
		}
	}

}