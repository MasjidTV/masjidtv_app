package my.israk.masjidtv_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PersistableBundle
import android.provider.Settings
import android.widget.Toast
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    @RequiresApi(Build.VERSION_CODES.M)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // https://stackoverflow.com/questions/70795926/flutter-app-boot-completed-receiver-doesnt-work
        var REQUEST_OVERLAY_PERMISSIONS = 100
        // Overlay permission is only required for Marshmallow (API 23) and above.
        // In previous APIs this permission is provided by default.
        if (!Settings.canDrawOverlays(getApplicationContext())) {
            val myIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
            val uri: Uri = Uri.fromParts("package", getPackageName(), null)
            myIntent.setData(uri)
            startActivityForResult(myIntent, REQUEST_OVERLAY_PERMISSIONS)
            Toast.makeText(getApplicationContext(),"App started",Toast.LENGTH_SHORT).show();
            return
        }
    }

}
