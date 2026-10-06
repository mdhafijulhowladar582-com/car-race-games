package com.hafijulnovalabs.firebasegooglesignin;

import android.app.Activity;
import android.content.Intent;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.tasks.Task;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.Set;

public class GodotAndroidPlugin extends GodotPlugin {
    private static final int SIGN_IN_REQUEST_CODE = 7017;
    private static final String WEB_CLIENT_ID = "798392879527-le0lmg8v3efab4ls9kdh8bk8fl4m02q1.apps.googleusercontent.com";
    private GoogleSignInClient googleClient;

    public GodotAndroidPlugin(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "FirebaseGoogleSignIn";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        return Set.of(
            new SignalInfo("google_sign_in_success", String.class, String.class, String.class),
            new SignalInfo("google_sign_in_failed", String.class),
            new SignalInfo("google_sign_out_complete")
        );
    }

    @UsedByGodot
    public void signIn() {
        Activity currentActivity = getActivity();
        if (currentActivity == null) {
            emitSignal("google_sign_in_failed", "Android activity is unavailable.");
            return;
        }

        currentActivity.runOnUiThread(() -> {
            GoogleSignInOptions options = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestIdToken(WEB_CLIENT_ID)
                .requestEmail()
                .build();

            googleClient = GoogleSignIn.getClient(currentActivity, options);
            Intent intent = googleClient.getSignInIntent();
            currentActivity.startActivityForResult(intent, SIGN_IN_REQUEST_CODE);
        });
    }

    @UsedByGodot
    public void signOut() {
        if (googleClient == null) {
            Activity currentActivity = getActivity();
            if (currentActivity == null) {
                emitSignal("google_sign_in_failed", "Android activity is unavailable.");
                return;
            }

            GoogleSignInOptions options = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestIdToken(WEB_CLIENT_ID)
                .requestEmail()
                .build();
            googleClient = GoogleSignIn.getClient(currentActivity, options);
        }

        googleClient.signOut().addOnCompleteListener(task -> emitSignal("google_sign_out_complete"));
    }

    @Override
    public void onMainActivityResult(int requestCode, int resultCode, Intent data) {
        super.onMainActivityResult(requestCode, resultCode, data);

        if (requestCode != SIGN_IN_REQUEST_CODE) {
            return;
        }

        if (resultCode != Activity.RESULT_OK) {
            emitSignal("google_sign_in_failed", "Google Sign-In was cancelled.");
            return;
        }

        if (data == null) {
            emitSignal("google_sign_in_failed", "Google Sign-In returned no result.");
            return;
        }

        try {
            Task<GoogleSignInAccount> task = GoogleSignIn.getSignedInAccountFromIntent(data);
            GoogleSignInAccount account = task.getResult(ApiException.class);
            String idToken = account.getIdToken();
            if (idToken == null || idToken.isEmpty()) {
                emitSignal("google_sign_in_failed", "Google ID token was not returned.");
                return;
            }

            emitSignal(
                "google_sign_in_success",
                idToken,
                account.getDisplayName() == null ? "" : account.getDisplayName(),
                account.getEmail() == null ? "" : account.getEmail()
            );
        } catch (ApiException exception) {
            emitSignal("google_sign_in_failed", "Google Sign-In failed: " + exception.getStatusCode());
        } catch (Exception exception) {
            emitSignal("google_sign_in_failed", "Google Sign-In returned an invalid account.");
        }
    }
}
