package com.moodstocks.android;

import java.io.IOException;
import java.lang.Void;

import com.loopj.android.http.AsyncHttpResponseHandler;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Rect;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View.OnClickListener;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.view.animation.Animation.AnimationListener;
import android.widget.ImageView;
import android.hardware.Camera;

public class Scanner extends Activity implements SurfaceHolder.Callback, OnClickListener, AnimationListener {
	
	private SurfaceHolder surface_holder;
	private ScannerHandler handler;
	protected Camera camera;
	protected boolean scanning;
	
	private Animation laser_effect;
	private Animation flash_effect;
	
	public static final class id {
		public static final int quit = 0;
		public static final int found = 1;
		public static final int nothing = 2;
		public static final int error = 3;
	}
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		
		/* initialize view */
		setContentView(R.layout.scanner_layout);
		findViewById(R.id.capture_button).setOnClickListener(this);
		
		/* initialize Moodstocks scanner */
		Bundle extras = getIntent().getExtras();
		if (extras != null) {
			String key = extras.getString("api_key");
			String secret = extras.getString("api_secret");
			Moodstocks.init(getApplication());
			Moodstocks.shared().setCredentials(key, secret);
		}
		
		/* initialize animations */
		flash_effect = AnimationUtils.loadAnimation(getApplication(), R.anim.flash_effect);
		laser_effect = AnimationUtils.loadAnimation(getApplication(), R.anim.laser_effect);
		flash_effect.setAnimationListener(this);
		laser_effect.setAnimationListener(this);
		
		/* initialize scanner handler */
		handler = new ScannerHandler(this);
	}
	
	@Override
	protected void onResume() {
		super.onResume();
		/* open camera if any, returns error otherwise */
		camera = Camera.open();
		if (camera == null) {
			Intent error = new Intent();
			error.putExtra("reason", "Camera Error");
			setResult(id.error, error);
			finish();
		}
		
		/* create surface_holder to display camera preview */
		restartView();
		surface_holder = ((SurfaceView) findViewById(R.id.surface_view)).getHolder();
		surface_holder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
		surface_holder.addCallback(this);
	}
	
	
	
	@Override
	protected void onPause() {
		this.scanning=false;
		/* release camera */
		camera.cancelAutoFocus();
		camera.stopPreview();
		camera.release();
		super.onPause();
	}
	
	@Override
	public void onBackPressed() {
		/* behavior of the "back" button:
		   - if "capture" button was pressed before: cancel scan
		   - otherwise, go back to main screen ("normal" behavior) */
		if (scanning) {
			camera.cancelAutoFocus();
			restartView();
			scanning = false;
		}
		else {
			setResult(Scanner.id.quit);
			super.onBackPressed();
		}
	}
	
	/* resets the different view to their initial visibility */
	private void restartView() {
		findViewById(R.id.flash).setVisibility(View.GONE);
		findViewById(R.id.freeze).setVisibility(View.GONE);
		findViewById(R.id.loading).setVisibility(View.GONE);
		findViewById(R.id.laser).setVisibility(View.GONE);
		findViewById(R.id.flash).clearAnimation();
		findViewById(R.id.laser).clearAnimation();
		findViewById(R.id.capture_button).setVisibility(View.VISIBLE);
		findViewById(R.id.surface_view).setVisibility(View.VISIBLE);
		findViewById(R.id.camera_loading).setVisibility(View.GONE);
	}
	
	/***************
	 * FLASH EFFECT
	 ***************/
	public void flashAndFreeze(Bitmap bmp) {
		/* flash */
		ImageView flash = (ImageView)findViewById(R.id.flash);
		flash.startAnimation(flash_effect);
		/* freeze */
		ImageView freeze = (ImageView)findViewById(R.id.freeze);		
		freeze.setImageBitmap(bmp);
		freeze.setVisibility(View.VISIBLE);
	}
	
	/***************
	 * LASER EFFECT
	 ***************/
	public void laserEffect() {
		View laser = findViewById(R.id.laser);
		laser.startAnimation(laser_effect);
	}
	
	
	/******************
	 * ONCLICKLISTENER
	 ******************/
	@Override
	public void onClick(View v) {
		switch(v.getId()) {
		case R.id.capture_button:
			scanning = true;
			handler.query();
			break;
		}
	}

	/*************************
	 * SURFACEHOLDER CALLBACK
	 *************************/
	@Override
	public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
		// void implementation
	}

	@Override
	public void surfaceCreated(SurfaceHolder holder) {
		findViewById(R.id.camera_loading).setVisibility(View.VISIBLE);
		//we use an AsyncTask to avoid ugly lag when camera is loading...
		new InitCamera().execute(holder); 
	}

	@Override
	public void surfaceDestroyed(SurfaceHolder holder) {
		// void implementation
	}
	
	/*********************
	 * ANIMATION CALLBACK
	 *********************/
	@Override
	public void onAnimationEnd(Animation animation) {
		if (animation.equals(flash_effect)) {
			// end of flash: hide flash and start laser effect
			findViewById(R.id.flash).setVisibility(View.GONE);
			laserEffect();
		}
		else {
			// end of laser effect: hide it
			findViewById(R.id.laser).setVisibility(View.GONE);
		}
	}
	
	@Override
	public void onAnimationRepeat(Animation animation) {
		// void implementation
	}
	
	@Override
	public void onAnimationStart(Animation animation) {
		if (animation.equals(flash_effect)) {
			// set flash visible
			findViewById(R.id.flash).setVisibility(View.VISIBLE);
		}
		else {
			// set laser effect visible
			findViewById(R.id.laser).setVisibility(View.VISIBLE);
		}
	}
	
/************************
 * CAMERA INITIALIZATION
 ************************/
	private class InitCamera extends AsyncTask<SurfaceHolder, Void, Boolean> {
		
		@Override
		protected Boolean doInBackground(SurfaceHolder... holder) {
			/* initialize camera parameters and start Preview */
			Rect dim = holder[0].getSurfaceFrame();
			int w = dim.width();
			int h = dim.height();
			Camera.Parameters params = camera.getParameters();
			params.setPreviewSize(w, h);
			camera.setParameters(params);
			try {
				camera.setPreviewDisplay(surface_holder);
			} catch (IOException e) {
				e.printStackTrace();
			}
			camera.startPreview();
			return true;
		}
		
		@Override
		protected void onPostExecute(Boolean a) {
			findViewById(R.id.camera_loading).setVisibility(View.GONE);
		}
	}
}
