namespace CCModManager;

public unsafe class CmdPollWaitBatch : Cmd<string, int?, object[]?> {
	public override bool     LogRun                   => false;
	public override bool     Taskable                 => true;
	public override object[]? Run(string id, int? max) => CmdTasks.Get(id)?.WaitBatch(max ?? 0);
}