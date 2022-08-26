using System;
using System.Net.Http;
using System.Threading.Tasks;

namespace CCModManager;

public unsafe class CmdWebGet : /*Cmd<string, byte[]>*/ AsyncCmd
{
	public override Type InputType  => typeof(Tuple<string>);
	public override Type OutputType => typeof(byte[]);
	public override bool LogRun     => false;

	public override Task<object?> RunAsync(object input)
	{
		var url = ((Tuple<string>) input).Item1;
		
		try
		{
			using var hc = new HttpClient();
			hc.DefaultRequestHeaders.Add("User-Agent", "CCDirectLink.CCModManager.Sharp");
			hc.DefaultRequestHeaders.Add("Accept",     "*/*");
			return hc.GetByteArrayAsync(url).ObjectifyTask();
		} catch (Exception e) {
			throw new Exception($"Failed downloading {url}", e);
		}
	}
}