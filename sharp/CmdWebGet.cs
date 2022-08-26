using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Text;

namespace CCModManager;

public unsafe class CmdWebGet : Cmd<string, byte[]> {
	public override bool LogRun   => false;
	public override bool Taskable => true;

	public override byte[] Run(string url) {
		try
		{
			var req = new HttpRequestMessage(HttpMethod.Get, url);
			req.Headers.Add("User-Agent", "CCDirectLink.CCModManager.Sharp");
			req.Headers.Add("Accept",     "*/*");
				
			using var hc     = new HttpClient();
			var       stream = hc.Send(req).Content.ReadAsStream();
			using var sr     = new StreamReader(stream);
			return Encoding.Default.GetBytes(sr.ReadToEnd());
				
			/*using var hc = new HttpClient();
			hc.DefaultRequestHeaders.Add("User-Agent", "CCDirectLink.CCModManager.Sharp");
			hc.DefaultRequestHeaders.Add("Accept",     "#1#*");
			return hc.GetByteArrayAsync(url);*/

			/*using (var wc = new WebClient()) {
				wc.Headers.Set(HttpRequestHeader.UserAgent, $"CCDirectLink.CCModManager.Sharp");
				wc.Headers.Set(HttpRequestHeader.Accept,    "#2#*");
				return wc.DownloadData(url);
			}*/
		} catch (Exception e) {
			throw new Exception($"Failed downloading {url}", e);
		}
	}
}