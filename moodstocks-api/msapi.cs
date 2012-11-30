using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;
using System.IO;

namespace MoodStocks {

    public class MoodStocksWrapper {

        private string apiKey;
        private string secretKey;
        public string userAgent = "moodstocks .net client v1.0.0.0. in c#";

        private string baseUri = "http://api.moodstocks.com/v2/{0}";

        private CredentialCache credentials = new CredentialCache();

        public MoodStocksWrapper(string apiKey, string secretKey) {
            this.apiKey = apiKey;
            this.secretKey = secretKey;
            credentials.Add(new Uri("http://api.moodstocks.com/"), "Digest", new NetworkCredential(apiKey, secretKey)); //, "Moodstocks API"
        }

        /// <summary>
        /// Use the api key to echo a message and verify the api key is correct.
        /// </summary>
        /// <param name="messageToEcho">The message to echo</param>
        /// <returns>The message passed in or an error</returns>
        public string Echo(string messageToEcho) {

            //Digest Auth in .net will not work as a get, trust me I tried. We will use a POST
            var queryString = "echo";

            var request = (HttpWebRequest)WebRequest.Create(string.Format(baseUri, queryString));
            request.UserAgent = userAgent;
            request.PreAuthenticate = true;

            request.Credentials = credentials;
            request.Method = "POST";

            using (var requestStream = request.GetRequestStream()) {
                var sw = new StreamWriter(requestStream);
                sw.Write(messageToEcho);
                sw.Flush();

                using (HttpWebResponse response = (HttpWebResponse)request.GetResponse()) {
                    using (var reader = new StreamReader(response.GetResponseStream())) {
                        return reader.ReadToEnd();
                    }
                }
            }
        }

        /// <summary>
        /// Add an image at a given end point.
        /// </summary>
        /// <param name="imageId"></param>
        /// <param name="imageData"></param>
        /// <returns></returns>
        public string AddImage(string imageId, Stream imageData) {

            //Digest Auth in .net will not work as a get, trust me I tried. We will use a POST
            var queryString = string.Format("ref/{0}", imageId);

            // Generate post objects
            Dictionary<string, object> postParameters = new Dictionary<string, object>();
            postParameters.Add("image_file", imageData);

            // Create request and receive response
            string postURL = string.Format(baseUri, queryString);

            using (HttpWebResponse webResponse = WebHelpers.MultipartFormDataPost(credentials, postURL, true, userAgent, postParameters)) {
                // Process response
                using (StreamReader responseReader = new StreamReader(webResponse.GetResponseStream())) {
                    return responseReader.ReadToEnd();
                }
            }
        }

        /// <summary>
        /// Remove an image at a given end point.
        /// </summary>
        /// <param name="imageId"></param>
        /// <param name="imageData"></param>
        /// <returns></returns>
        public string RemoveImage(string imageId) {

            var queryString = string.Format("ref/{0}", imageId);

            var request = (HttpWebRequest)WebRequest.Create(string.Format(baseUri, queryString));
            request.UserAgent = userAgent;
            request.PreAuthenticate = true;

            request.Credentials = credentials;
            request.Method = "DELETE";

            using (var requestStream = request.GetRequestStream()) {
                using (HttpWebResponse response = (HttpWebResponse)request.GetResponse()) {
                    using (var reader = new StreamReader(response.GetResponseStream())) {
                        return reader.ReadToEnd();
                    }
                }
            }
        }

        /// <summary>
        /// Search for an image.
        /// </summary>
        /// <param name="imageData"></param>
        /// <returns></returns>
        public string Search(Stream imageData) {

            var queryString = "search";

            // Generate post objects
            Dictionary<string, object> postParameters = new Dictionary<string, object>();
            postParameters.Add("image_file", imageData);

            // Create request and receive response
            string postURL = string.Format(baseUri, queryString);

            using (HttpWebResponse webResponse = WebHelpers.MultipartFormDataPost(credentials, postURL, false, userAgent, postParameters)) {
                // Process response
                using (StreamReader responseReader = new StreamReader(webResponse.GetResponseStream())) {
                    return responseReader.ReadToEnd();
                }
            }
        }
    }

    //credit to Brian Grinstead @ stackoverflow
    //http://stackoverflow.com/questions/219827/multipart-forms-from-c-client
    public static class WebHelpers {

        public static Encoding encoding = Encoding.UTF8;

        /// <summary>
        /// Post the data as a multipart form
        /// postParameters with a value of type Stream will be passed in the form as a file, and value of type string will be
        /// passed as a name/value pair.
        /// </summary>
        public static HttpWebResponse MultipartFormDataPost(CredentialCache credentials, string postUrl, bool isPut, string userAgent,
            Dictionary<string, object> postParameters) {

            string formDataBoundary = "----------------------------36d465e3ee6c";
            string contentType = "multipart/form-data; boundary=" + formDataBoundary;

            using (var formData = WebHelpers.GetMultipartFormData(postParameters, formDataBoundary)) {
                return WebHelpers.PostForm(credentials, postUrl, isPut, userAgent, contentType, formData);
            }
        }

        /// <summary>
        /// Post a form
        /// </summary>
        private static HttpWebResponse PostForm(CredentialCache credentials, string postUrl, bool isPut, string userAgent, string contentType, Stream formData) {
            HttpWebRequest request = WebRequest.Create(postUrl) as HttpWebRequest;

            if (request == null) {
                throw new NullReferenceException("request is not a http request");
            }

            request.PreAuthenticate = true;
            request.Credentials = credentials;

            // Add these, as we're doing a PUT
            request.Method = isPut ? "PUT" : "POST";
            request.ContentType = contentType;
            request.UserAgent = userAgent;

            // We need to count how many bytes we're sending.
            request.ContentLength = formData.Length;

            using (Stream requestStream = request.GetRequestStream()) {
                formData.CopyTo(requestStream);
            }

            return request.GetResponse() as HttpWebResponse;
        }

        /// <summary>
        /// Turn the key and value pairs into a multipart form.
        /// See http://www.ietf.org/rfc/rfc2388.txt for issues about file uploads
        /// </summary>
        private static Stream GetMultipartFormData(Dictionary<string, object> postParameters, string boundary) {
            var outStream = new MemoryStream();

            foreach (var param in postParameters) {
                if (param.Value is Stream) {
                    var fileData = param.Value as Stream;
                    //NOTE: Moodstocks does not work if there is a ; after the filename before the \r\n
                    //Add just the first part of this param, since we will write the file data directly to the Stream
                    string header = string.Format("--{0}\r\nContent-Disposition: form-data; name=\"{1}\"; filename=\"{2}\"\r\nContent-Type: image/jpeg\r\n\r\n", boundary, param.Key, "image.jpg");
                    outStream.Write(encoding.GetBytes(header), 0, header.Length);
                    fileData.CopyTo(outStream);
                }
                else {
                    string postData = string.Format("--{0}\r\nContent-Disposition: form-data; name=\"{1}\"\r\n\r\n{2}\r\n", boundary, param.Key, param.Value);
                    outStream.Write(encoding.GetBytes(postData), 0, postData.Length);
                }
            }

            // Add the end of the request
            string footer = "\r\n--" + boundary + "--\r\n";
            outStream.Write(encoding.GetBytes(footer), 0, footer.Length);
            outStream.Flush();
            outStream.Position = 0;
            return outStream;
        }
    }

    class Program {

        static void Main(string[] args) {

            var ms = new MoodStocksWrapper("api key", "secret key");

            //echo
            var echo = ms.Echo("test=1&hello=world");

            Console.WriteLine(echo);

            //upload an image
            using (var fs = File.OpenRead("[Path to Image you wish to upload]")) {
                var addimage = ms.AddImage("your id you wish to use", fs);
                Console.WriteLine(addimage);
            }

            //search for an image
            using (var fs = File.OpenRead("[Path to Image you wish to search]")) {
                var search = ms.Search(fs);
                Console.WriteLine(search);
            }

            //remove an image
            var remove = ms.RemoveImage("your id you wish to use");
            Console.WriteLine(remove);

            Console.WriteLine("Press any key to exit");
            Console.ReadLine();

        }
    }
}
