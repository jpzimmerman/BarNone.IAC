using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Data.SqlClient;
using Newtonsoft.Json;
using System;
using System.Data;
using System.Threading.Tasks;
using System.Web.Http;

namespace GetOrders
{
    public static class GetOrdersFunction
    {
        [FunctionName("GetOrders")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = null)] HttpRequest req)
        {
            try
            {
                using (var connection = new SqlConnection("DB_CONNECTION"))
                {
                    var command = new SqlCommand("GetOrders", connection)
                    {
                        CommandType = CommandType.StoredProcedure
                    };
                    connection.Open();
                    using var reader = await command.ExecuteReaderAsync();
                    var dataTable = new DataTable();
                    dataTable.Load(reader);
                    var serializedResult = JsonConvert.SerializeObject(dataTable);
                    return new OkObjectResult(serializedResult);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"GetOrders() error: {ex.Message}");
                return new InternalServerErrorResult();
            }
        }
    }
}
