/*
 * This snippet is not good Java style and we are aware of it.
 * However we thought it was simpler for example purpose.
 * 
 * It works with Apache HttpClient 4.1.1, which can be used on Android.
 * Feel free to use any other library of your choice.
 * However, please note that you should not use Jersey since its
 * Digest Authentication code appears to be broken with query strings.
 */


package moodstocks;

import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import org.apache.http.HttpEntity;
import org.apache.http.HttpHost;
import org.apache.http.HttpRequest;
import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.methods.HttpDelete;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpPut;
import org.apache.http.client.utils.URIUtils;
import org.apache.http.client.utils.URLEncodedUtils;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.ContentBody;
import org.apache.http.entity.mime.content.FileBody;
import org.apache.http.impl.auth.DigestScheme;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.protocol.BasicHttpContext;
import org.apache.http.util.EntityUtils;

public class ApiDemo {

    // Settings
    private static String key = "YourApiKey";
    private static String secret = "YourApiSecret";
    private static String imageFilename =
            ApiDemo.class.getResource("sample.jpg").getPath();
    private static String imageUrl = "http://api.moodstocks.com/static/sample-book.jpg";
    private static String sampleId = "test1234";
    
    // Boilerplate
    private static HttpHost targetHost;
    private static BasicHttpContext context;
    private static DefaultHttpClient client;

    public static void init() {
        client = new DefaultHttpClient();
        targetHost = new HttpHost("api.moodstocks.com", 80, "http");
        AuthScope authScope =
                new AuthScope(targetHost.getHostName(), targetHost.getPort());
        UsernamePasswordCredentials credentials =
                new UsernamePasswordCredentials(key, secret);
        client.getCredentialsProvider().setCredentials(authScope, credentials);
        context = new BasicHttpContext();
        context.setAttribute("preemptive-auth", new DigestScheme());
    }

    public static void clean() {
        client.getConnectionManager().shutdown();
    }

    public static void disp(HttpRequest rq) throws IOException {
        HttpResponse response = client.execute(targetHost, rq, context);
        HttpEntity entity = response.getEntity();
        System.out.println(EntityUtils.toString(entity));
    }

    public static void main(String[] args) throws IOException, URISyntaxException {

        init();

        // Authenticating with your API key (Echo service)
        HttpGet rq1 = new HttpGet("/v2/echo?foo=bar");
        disp(rq1);

        // Image + Multipart 
        File image = new File(imageFilename);
        ContentBody body =
                new FileBody(image, "image/jpeg", "image_file", null);
        MultipartEntity multipartContent = new MultipartEntity();
        multipartContent.addPart("image_file", body);

        // Adding objects to recognize
        String sampleResource = "/v2/ref/" + sampleId;
        HttpPut rq2 = new HttpPut(sampleResource);
        rq2.setEntity(multipartContent);
        disp(rq2);

        // Looking up objects
        HttpPost rq3 = new HttpPost("/v2/search");
        rq3.setEntity(multipartContent);
        disp(rq3);

        // Updating a reference & using a hosted image
        List<NameValuePair> rq4params = new ArrayList<NameValuePair>();
        rq4params.add(new BasicNameValuePair("image_url", imageUrl));
        String rq4qs = URLEncodedUtils.format(rq4params, "UTF-8");
        HttpPut rq4 = new HttpPut("/v2/ref/" + sampleId + "?" + rq4qs);
        disp(rq4);
        
        // Removing reference images
        HttpDelete rq5 = new HttpDelete(sampleResource);
        disp(rq5);

        clean();

    }
}