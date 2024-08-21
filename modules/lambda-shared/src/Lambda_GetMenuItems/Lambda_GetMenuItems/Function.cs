using Amazon.Lambda.Core;
using Amazon.RDS.Util;
using MySqlConnector;
using System;
using System.Collections.Generic;
using System.Data;
using System.Text.Json.Serialization;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace Lambda_GetMenuItems
{
    public class MenuItem
    {
        [JsonPropertyName("id")]
        public int Id { get; set; }

        [JsonPropertyName("name")]
        public string Name { get; set; }

        [JsonPropertyName("description")]
        public string Description { get; set; }

        [JsonPropertyName("SpecialInstructions")]
        public string SpecialInstructions { get; set; }

        [JsonPropertyName("ingredients")]
        public List<string> Ingredients { get; set; }

        [JsonPropertyName("price")]
        public float Price { get; set; }

        [JsonPropertyName("numberOfOrders")]
        public uint NumberOfOrders { get; set; }

        [JsonPropertyName("category")]
        public string Category { get; set; }
    }


    public class Function
    {
        
        /// <summary>
        /// A simple function that takes a string and does a ToUpper
        /// </summary>
        /// <param name="input"></param>
        /// <param name="context"></param>
        /// <returns></returns>
        public IEnumerable<MenuItem> FunctionHandler(ILambdaContext context)
        {
            var items = new List<MenuItem>();

            var pwd = RDSAuthTokenGenerator.GenerateAuthToken("db-server", 0000, "user");


            using (var connection = new MySqlConnection($"Server=db-server;port=0000;user=user;password={pwd};Database=cocktails;SslMode=Required;SslCa=./cert.pem"))
            {
                var command = new MySqlCommand("GetMenuItems", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                connection.Open();
                using var reader = command.ExecuteReader();
                while (reader.Read())
                {
                    items.Add(new MenuItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1),
                        Description = reader.GetString(2),
                        Price = reader.GetFloat(4),
                        Category = reader.GetString(6)
                    });
                }
            }
            return items;
        }
    }
}
