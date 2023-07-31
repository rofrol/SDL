package @ANDROID_MANIFEST_PACKAGE@;

import org.libsdl.app.SDL;
import org.libsdl.app.SDLActivity;

import android.app.Activity;
import android.app.AlertDialog;

import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;

import android.os.Bundle;

import android.util.Log;

import android.view.View;
import android.view.ViewGroup;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;

import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Spinner;
import android.widget.Toast;

public class SDLEntryTestActivity extends Activity {

    public String MODIFY_ARGUMENTS = "@ANDROID_MANIFEST_PACKAGE@.MODIFY_ARGUMENTS";
    boolean isModifyingArguments;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.v("SDL", "SDLEntryTestActivity onCreate");
        super.onCreate(savedInstanceState);

        String intent_action = getIntent().getAction();
        Log.v("SDL", "SDLEntryTestActivity intent.action = " + intent_action);

        if (intent_action == MODIFY_ARGUMENTS) {
            isModifyingArguments = true;
            createArgumentLayout();
        } else {
            startChildActivityAndFinish();
        }
    }

//    @Override
//    public boolean onCreateOptionsMenu(Menu menu) {
//        getMenuInflater().inflate(R.menu.menu, menu);
//        MenuItem item = menu.findItem(R.id.button_item);
//        Button btn = item.getActionView().findViewById(R.id.button);
//        btn.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View view) {
//                Toast.makeText(SDLEntryTestActivity.this, "Toolbar Button Clicked!", Toast.LENGTH_SHORT).show();
//            }
//        });
//        return true;
//    }

    protected void createArgumentLayout() {
        LayoutInflater inflater = getLayoutInflater();
        View view = inflater.inflate(R.layout.arguments_layout, null);
        setContentView(view);

        Button button = (Button)requireViewById(R.id.arguments_start_button);
        button.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                startChildActivityAndFinish();
            }
        });

        Spinner spinner = (Spinner)findViewById(R.id.sdl_audio_driver_spinner);
        ArrayAdapter<CharSequence> adapter = ArrayAdapter.createFromResource(this,
            R.array.sdl_audio_driver, android.R.layout.simple_spinner_item);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spinner.setAdapter(adapter);
    }

    protected String[] getArguments() {
        if (!isModifyingArguments) {
            return new String[0];
        }
        EditText editText = (EditText)findViewById(R.id.arguments_edit);
        String text = editText.getText().toString();
        String new_text = text.replace("[ \t]*[ \t\n]+[ \t]+", "\n").strip();
        Log.v("SDL", "text = " + text + "\n becomes \n" + new_text);
        return new_text.split("\n", 0);
    }

    @Override
    protected void onStart() {
        Log.v("SDL", "SDLEntryTestActivity onStart");
        super.onStart();
    }

    @Override
    protected void onResume() {
        Log.v("SDL", "SDLEntryTestActivity onResume");
        super.onResume();
    }

    @Override
    protected void onPause() {
        Log.v("SDL", "SDLEntryTestActivity onPause");
        super.onPause();
    }

    @Override
    protected void onStop() {
        Log.v("SDL", "SDLEntryTestActivity onStop");
        super.onStop();
    }

    @Override
    protected void onDestroy() {
        Log.v("SDL", "SDLEntryTestActivity onDestroy");
        super.onDestroy();
    }

    @Override
    protected void onRestoreInstanceState(Bundle savedInstanceState) {
        Log.v("SDL", "SDLEntryTestActivity onRestoreInstanceState");
        super.onRestoreInstanceState(savedInstanceState);
        EditText editText = (EditText)findViewById(R.id.arguments_edit);
        editText.setText(savedInstanceState.getCharSequence("args", ""), TextView.BufferType.EDITABLE);
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        Log.v("SDL", "SDLEntryTestActivity onSaveInstanceState");
        EditText editText = (EditText)findViewById(R.id.arguments_edit);
        outState.putCharSequence("args", editText.getText());
        super.onSaveInstanceState(outState);
    }

    private void startChildActivityAndFinish() {
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.addCategory(Intent.CATEGORY_LAUNCHER);
        intent.setClassName("@ANDROID_MANIFEST_PACKAGE@", "@ANDROID_MANIFEST_PACKAGE@.SDLTestActivity");
        intent.putExtra("arguments", getArguments());

        Spinner spinner = (Spinner)findViewById(R.id.sdl_audio_driver_spinner);
        int audio_driver_index = spinner.getSelectedItemPosition();
        if (audio_driver_index != 0) {
            String[] audio_driver_array = getResources().getStringArray(R.array.sdl_audio_driver);
            String audio_driver = audio_driver_array[audio_driver_index];
            intent.putExtra("audio_driver", audio_driver);
        }

        startActivity(intent);
        finish();
    }
}
