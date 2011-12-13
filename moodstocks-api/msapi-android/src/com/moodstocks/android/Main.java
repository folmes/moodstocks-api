package com.moodstocks.android;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.view.View;
import android.view.View.OnClickListener;
import android.os.Bundle;

public class Main extends Activity implements OnClickListener {
	
	static final String TAG = "Main";
	static final private int MS_CODE = 0;
	
	
	/****************************************************
	 *                  IMPORTANT!
	 * Be sure to replace these values with your actual
	 * Moodstocks API key and secret.
	 ****************************************************/
	static final String MS_API = "MS_API_KEY";
	static final String MS_SECRET = "MS_API_SECRET";
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);
		findViewById(R.id.scan_button).setOnClickListener(this);
	}

	@Override
	public void onClick(View v) {
		switch (v.getId()) {
		case R.id.scan_button:
			// Launches scanner
			Intent i = new Intent(this, Scanner.class);
			i.putExtra("api_key", MS_API);
			i.putExtra("api_secret", MS_SECRET);
			startActivityForResult(i, MS_CODE);
			break;
		}
	}
	
	/* handle result */
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		if (requestCode == MS_CODE) {
    	if (resultCode != Scanner.id.quit) {
	    	AlertDialog.Builder dialog = new AlertDialog.Builder(this);
				if (resultCode == Scanner.id.found) {
					dialog.setMessage("Found: "+data.getStringExtra("ObjectID"));
				}
				else if (resultCode == Scanner.id.nothing) {
					dialog.setMessage("Nothing Found");
				}
				else if (resultCode == Scanner.id.error) {
					dialog.setMessage(data.getStringExtra("reason"));
				}
	      dialog.setNeutralButton("OK", null);
	      dialog.create().show();
    	}
		}
	}
}