package com.moodstocks.android;

import java.io.ByteArrayOutputStream;
import java.net.ConnectException;
import java.net.UnknownHostException;

import org.apache.http.client.HttpResponseException;
import org.json.JSONException;
import org.json.JSONObject;

import com.moodstocks.android.Scanner.id;
import com.loopj.android.http.JsonHttpResponseHandler;

import android.content.Intent;
import android.graphics.Bitmap;
import android.view.View;
import android.hardware.Camera;

public class ScannerHandler implements Camera.PreviewCallback, Camera.AutoFocusCallback {
	
	private static final int MAX_DIM = 480;
	private static final int JPEG_QUALITY = 93;
	
	private Scanner scanner;
	
	ScannerHandler(Scanner scan) {
		this.scanner = scan;
	}
	
	/* query starts by focussing... */
	public void query() {
		scanner.findViewById(R.id.capture_button).setVisibility(View.GONE);
		scanner.findViewById(R.id.loading).setVisibility(View.VISIBLE);
		scanner.camera.autoFocus(this);
	}
	
	/* then capturing... */
	@Override
	public void onAutoFocus(boolean success, Camera camera) {
		scanner.findViewById(R.id.loading).setVisibility(View.GONE);
		scanner.camera.setOneShotPreviewCallback(this);
	}
	
	/* and finally sending to API! */
	@Override
	public void onPreviewFrame(byte[] data, Camera camera) {
		Camera.Size size = camera.getParameters().getPreviewSize();
		/* launch flash and freeze effect */
		Bitmap frozenPreview = yuvToRgbBitmap(data, size.width, size.height);
		scanner.flashAndFreeze(frozenPreview);
		/* convert to jpeg and send to API */
		byte[] query = compressYuvToGrayscaledJpeg(data, size.width, size.height, MAX_DIM,
				JPEG_QUALITY);
		Moodstocks.shared().search(query, mHttpHandler);
	}
	
	/*************************
	 * IMAGE CONVERSION TOOLS
	 *************************/
	private static Bitmap yuvToRgbBitmap(byte[] yuvData, int width, int height) {
		// NV21 -> RGB conversion
		int[] rgb = new int[width*height];
		byte[] yuv = yuvData;
		
    for (int j = 0, yp = 0; j < height; j++) {      
    	int uvp = width*height + (j >> 1) * width, u = 0, v = 0;  
      for (int i = 0; i < width; i++, yp++) {  
        int y = (0xff & ((int) yuv[yp])) - 16;  
        if (y < 0)  
          y = 0;  
        if ((i & 1) == 0) {  
          v = (0xff & yuv[uvp++]) - 128;  
          u = (0xff & yuv[uvp++]) - 128;  
        }  

        int y1192 = 1192 * y;  
        int r = (y1192 + 1634 * v);  
        int g = (y1192 - 833 * v - 400 * u);  
        int b = (y1192 + 2066 * u);  

        if (r < 0)                  
        	r = 0;               
        else if (r > 262143)  
           r = 262143;  
        if (g < 0)                  
        	g = 0;               
        else if (g > 262143)  
           g = 262143;  
        if (b < 0)                  
        	b = 0;              
        else if (b > 262143)  
           b = 262143;  

        rgb[yp] = 0xff000000 | ((r << 6) & 0xff0000) | ((g >> 2) & 0xff00) | ((b >> 10) & 0xff);  
      }  
    }  
    
		Bitmap bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
		bmp.setPixels(rgb, 0, width, 0, 0, width, height);
		return bmp;
	}
	
	private static byte[] compressYuvToGrayscaledJpeg(byte[] yuvData, int width,
			int height, int maxSize, int quality) {
		// NV21 -> grayscale conversions
		int[] pixels = new int[width * height];
		byte[] yuv = yuvData;
		int inputOffset = 0;
		
		for (int y = 0; y < height; y++) {
			int outputOffset = y * width;
			for (int x = 0; x < width; x++) {
				int grey = yuv[inputOffset + x] & 0xff;
				pixels[outputOffset + x] = 0xFF000000 | (grey * 0x00010101);
			}
			inputOffset += width;
		}

		Bitmap bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
		bmp.setPixels(pixels, 0, width, 0, 0, width, height);

		Bitmap out = bmp;
		
		// Resizing up to max size
		int maxDim = width > height ? width : height;
		if (maxDim > maxSize) {
			float ratio = ((float) maxSize) / ((float) maxDim);
			out = Bitmap.createScaledBitmap(bmp, Math.round(ratio * width),
					Math.round(ratio * height), true);
		}

		// JPEG compression
		ByteArrayOutputStream stream = new ByteArrayOutputStream();
		out.compress(Bitmap.CompressFormat.JPEG, quality, stream);

		return stream.toByteArray();
	}
	
	
	/**********************************
	 * JSON Response Handler
	 **********************************/
	JsonHttpResponseHandler mHttpHandler = new JsonHttpResponseHandler() {

		public void onSuccess(JSONObject obj) {
			try {
				if (scanner.scanning) {
					boolean found = obj.getBoolean("found");
					if (found) {
						String id = obj.getString("id");
						Intent result = new Intent();
						result.putExtra("ObjectID", id);
						scanner.setResult(Scanner.id.found, result);
						scanner.finish();
					}
					else {
						scanner.setResult(Scanner.id.nothing);
						scanner.finish();
					}
				}
			} catch (JSONException e) {
				e.printStackTrace();
			}
		}

		public void onFailure(Throwable error) {
			String reason = "Unknown";
			if (error instanceof HttpResponseException) {
				HttpResponseException err = (HttpResponseException) error;
				if (err.getStatusCode() == 401) {
					reason = "Invalid credentials";
				}
			}
			else if (error instanceof ConnectException) {
				ConnectException err = (ConnectException) error;
				if (err.getCause() instanceof UnknownHostException) {
					reason = "No connection";
				}
			}
			Intent i = new Intent();
			i.putExtra("reason", reason);
			scanner.setResult(id.error, i);
			scanner.finish();
		}
	};

}
