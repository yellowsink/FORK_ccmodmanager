namespace CCModManager;

public class CmdEcho : Cmd<string, string> {
	public override bool   LogRun           => false;
	public override string Run(string data) => data;
}