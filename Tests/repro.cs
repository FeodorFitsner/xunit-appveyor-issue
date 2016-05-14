using System;
using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Owin.Testing;
using Owin;
using Xunit;

namespace Tests
{
    public class Startup
    {
        public static void Configuration(IAppBuilder app)
        {
            Trace.TraceInformation("Hello?");
            // New code:
            app.Run(context =>
            {
                context.Response.ContentType = "text/plain";
                return context.Response.WriteAsync("Hello, world.");
            });
        }
    }

    public class Tests
    {
        [Fact]
        public async Task Test()
        {
            TestServer _server = TestServer.Create(Startup.Configuration);
            var request = new HttpRequestMessage(HttpMethod.Get, new Uri("http://localhost/hi"));
            request.Headers.Host = request.RequestUri.Host;
            var response = await _server.HttpClient.SendAsync(request);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        }
    }
}
