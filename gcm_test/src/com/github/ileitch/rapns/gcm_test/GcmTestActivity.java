package com.github.ileitch.rapns.gcm_test;

import static com.github.ileitch.rapns.gcm_test.CommonUtilities.SENDER_ID;
import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.widget.TextView;

import com.google.android.gcm.GCMRegistrar;

public class GcmTestActivity extends Activity {

	private String TAG = "** pushAndroidActivity **";
	private TextView mDisplay;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		
		checkNotNull(SENDER_ID, "SENDER_ID");

		GCMRegistrar.checkDevice(this);
		GCMRegistrar.checkManifest(this);

		setContentView(R.layout.main);
		mDisplay = (TextView) findViewById(R.id.display);
		
		final String regId = GCMRegistrar.getRegistrationId(this);
		Log.i(TAG, "registration id: " + regId);

		if (regId.equals("")) {
			GCMRegistrar.register(this, SENDER_ID);
		} else {
			Log.v(TAG, "Already registered");
		}

		mDisplay.setText(regId);
	}

	private void checkNotNull(Object reference, String name) {
		if (reference == null) {
			throw new NullPointerException(name);
		}
	}

	@Override
	protected void onPause() {
		super.onPause();
		GCMRegistrar.unregister(this);
	}
}
