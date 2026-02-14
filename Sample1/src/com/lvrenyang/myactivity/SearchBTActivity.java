package com.lvrenyang.myactivity;

import java.io.IOException;
import java.io.InputStream;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import com.lvrenyang.io.BTPrinting;
import com.lvrenyang.io.IOCallBack;
import com.lvrenyang.io.Pos;
import com.lvrenyang.sample1.R;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Bitmap.Config;
import android.os.Bundle;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.Toast;


public class SearchBTActivity extends Activity implements OnClickListener, IOCallBack {

	private LinearLayout linearlayoutdevices;
	private ProgressBar progressBarSearchStatus;

	private BroadcastReceiver broadcastReceiver = null;
	private IntentFilter intentFilter = null;

	Button btnSearch,btnDisconnect,btnPrint;
	SearchBTActivity mActivity;
	
	ExecutorService es = Executors.newScheduledThreadPool(30);
	Pos mPos = new Pos();
	BTPrinting mBt = new BTPrinting();
	
	private static String TAG = "SearchBTActivity";

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_searchbt);

		mActivity = this;
		
		progressBarSearchStatus = (ProgressBar) findViewById(R.id.progressBarSearchStatus);
		linearlayoutdevices = (LinearLayout) findViewById(R.id.linearlayoutdevices);
		
		btnSearch = (Button) findViewById(R.id.buttonSearch);
		btnDisconnect = (Button) findViewById(R.id.buttonDisconnect);
		btnPrint = (Button) findViewById(R.id.buttonPrint);
		btnSearch.setOnClickListener(this);
		btnDisconnect.setOnClickListener(this);
		btnPrint.setOnClickListener(this);
		btnSearch.setEnabled(true);
		btnDisconnect.setEnabled(false);
		btnPrint.setEnabled(false);
		
		mPos.Set(mBt);
		mBt.SetCallBack(this);
		
		initBroadcast();
	}

	@Override
	protected void onDestroy() {
		super.onDestroy();
		uninitBroadcast();
		btnDisconnect.performClick();
	}

	public void onClick(View arg0) {
		// TODO Auto-generated method stub
		switch (arg0.getId()) {
		case R.id.buttonSearch: {
			BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
			if (null == adapter) {
				finish();
				break;
			}

			if (!adapter.isEnabled()) {
				if (adapter.enable()) {
					while (!adapter.isEnabled())
						;
					Log.v(TAG, "Enable BluetoothAdapter");
				} else {
					finish();
					break;
				}
			}
			
			adapter.cancelDiscovery();
			linearlayoutdevices.removeAllViews();
			adapter.startDiscovery();
			break;
		}
		
		case R.id.buttonDisconnect:
			es.submit(new TaskClose(mBt));
			break;

		case R.id.buttonPrint:
			btnPrint.setEnabled(false);
			es.submit(new TaskPrint(mPos));
			break;
		}
	}

	private void initBroadcast() {
		broadcastReceiver = new BroadcastReceiver() {

			@Override
			public void onReceive(Context context, Intent intent) {
				// TODO Auto-generated method stub
				String action = intent.getAction();
				BluetoothDevice device = intent
						.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);

				if (BluetoothDevice.ACTION_FOUND.equals(action)) {
					if (device == null)
						return;
					final String address = device.getAddress();
					String name = device.getName();
					if (name == null)
						name = "BT";
					else if (name.equals(address))
						name = "BT";
					Button button = new Button(context);
					button.setText(name + ": " + address);
					
					for(int i = 0; i < linearlayoutdevices.getChildCount(); ++i)
					{
						Button btn = (Button)linearlayoutdevices.getChildAt(i);
						if(btn.getText().equals(button.getText()))
						{
							return;
						}
					}
					
					button.setGravity(android.view.Gravity.CENTER_VERTICAL
							| Gravity.LEFT);
					button.setOnClickListener(new OnClickListener() {

						public void onClick(View arg0) {
							// TODO Auto-generated method stub
							Toast.makeText(mActivity, "Connecting...", Toast.LENGTH_SHORT).show();
							btnSearch.setEnabled(false);
							linearlayoutdevices.setEnabled(false);
							for(int i = 0; i < linearlayoutdevices.getChildCount(); ++i)
							{
								Button btn = (Button)linearlayoutdevices.getChildAt(i);
								btn.setEnabled(false);
							}
							btnDisconnect.setEnabled(false);
							btnPrint.setEnabled(false);
							es.submit(new TaskOpen(mBt,address, mActivity));
							//es.submit(new TaskTest(mPos, mBt, address, mActivity));
						}
					});
					button.getBackground().setAlpha(100);
					linearlayoutdevices.addView(button);
				} else if (BluetoothAdapter.ACTION_DISCOVERY_STARTED
						.equals(action)) {
					progressBarSearchStatus.setIndeterminate(true);
				} else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED
						.equals(action)) {
					progressBarSearchStatus.setIndeterminate(false);
				}

			}

		};
		intentFilter = new IntentFilter();
		intentFilter.addAction(BluetoothDevice.ACTION_FOUND);
		intentFilter.addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED);
		intentFilter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
		registerReceiver(broadcastReceiver, intentFilter);
	}

	private void uninitBroadcast() {
		if (broadcastReceiver != null)
			unregisterReceiver(broadcastReceiver);
	}

	public class TaskTest implements Runnable
	{
		Pos pos = null;
		BTPrinting bt = null;
		String address = null;
		Context context = null;
		
		public TaskTest(Pos pos, BTPrinting bt, String address, Context context)
		{
			this.pos = pos;
			this.bt = bt;
			this.address = address;
			this.context = context;
			pos.Set(bt);
		}
		
		@Override
		public void run() {
			// TODO Auto-generated method stub
			for(int i = 0; i < 1000; ++i)
			{
				long beginTime = System.currentTimeMillis();
				if(bt.Open(address,context))
				{
					long endTime = System.currentTimeMillis();
					pos.POS_S_Align(0);
					pos.POS_S_TextOut(i+ " " + "Open   UsedTime:" + (endTime - beginTime) + "\r\n", 0, 0, 0, 0, 0);
					beginTime = System.currentTimeMillis();
					boolean ticketResult = pos.POS_TicketSucceed(i, 30000);
					endTime = System.currentTimeMillis();
					pos.POS_S_TextOut(i+ " " + "Ticket UsedTime:" + (endTime - beginTime) + " " + (ticketResult ? "Succeed" : "Failed") +  "\r\n", 0, 0, 0, 0, 0);
					pos.POS_Beep(1, 500);
					bt.Close();
				}
			}
		}
	}
	
	public class TaskOpen implements Runnable
	{
		BTPrinting bt = null;
		String address = null;
		Context context = null;
		
		public TaskOpen(BTPrinting bt, String address, Context context)
		{
			this.bt = bt;
			this.address = address;
			this.context = context;
		}
		
		@Override
		public void run() {
			// TODO Auto-generated method stub
			bt.Open(address,context);
		}
	}
	
	static int dwWriteIndex = 1;
	public class TaskPrint implements Runnable
	{
		Pos pos = null;
		
		public TaskPrint(Pos pos)
		{
			this.pos = pos;
		}
		
		@Override
		public void run() {
			// TODO Auto-generated method stub
			
			final boolean bPrintResult = PrintTicket(AppStart.nPrintWidth, AppStart.bCutter, AppStart.bDrawer, AppStart.bBeeper, AppStart.nPrintCount, AppStart.nCompressMethod);
			final boolean bIsOpened = pos.GetIO().IsOpened();
			
			mActivity.runOnUiThread(new Runnable(){
				@Override
				public void run() {
					// TODO Auto-generated method stub
					Toast.makeText(mActivity.getApplicationContext(), bPrintResult ? getResources().getString(R.string.printsuccess) : getResources().getString(R.string.printfailed), Toast.LENGTH_SHORT).show();
					mActivity.btnPrint.setEnabled(bIsOpened);
				}
			});

		}
		
	
		public boolean PrintTicket(int nPrintWidth, boolean bCutter, boolean bDrawer, boolean bBeeper, int nCount, int nCompressMethod)
		{
			boolean bPrintResult = false;
			
			//byte[] status = new byte[1];
			//if(pos.POS_QueryStatus(status, 3000, 2))
			{
				// 设置一下打印速度
				//int nPrintSpeed = AppStart.nBSPBaudrate / 10 / (nPrintWidth / 8 + 8) / 8;
				//pos.POS_SetPrintSpeed(nPrintSpeed);
				
				Bitmap bm1 = mActivity.getTestImage1(nPrintWidth, nPrintWidth);
				Bitmap bm2 = mActivity.getTestImage2(nPrintWidth, nPrintWidth);
				Bitmap bmBlackWhite = getImageFromAssetsFile("blackwhite.png");
				Bitmap bmIu = getImageFromAssetsFile("iu.jpeg");
				Bitmap bmYellowmen = getImageFromAssetsFile("yellowmen.png");
				bmIu = resizeImage(bmIu,nPrintWidth,bmIu.getHeight() * nPrintWidth / bmIu.getWidth());
				for(int i = 0; i < nCount; ++i)
				{
					if(!pos.GetIO().IsOpened())
						break;
					
					pos.POS_FeedLine();
					pos.POS_S_Align(1);
					pos.POS_S_TextOut("REC" + String.format("%03d", i) + "\r\nCaysn Printer\r\n测试页\r\n\r\n", 0, 1, 1, 0, 0x100);
					pos.POS_S_TextOut("扫二维码下载苹果APP\r\n", 0, 0, 0, 0, 0x100);
					pos.POS_S_SetQRcode("https://appsto.re/cn/2KF_bb.i", 8, 0, 3);
					pos.POS_FeedLine();
					pos.POS_S_SetBarcode("20160618", 0, 72, 3, 60, 0, 2);
					pos.POS_FeedLine();
					
					if(bm1 != null)
					{
						pos.POS_PrintPicture(bm1, nPrintWidth, 1, nCompressMethod);
					}
					if(bm2 != null)
					{
						pos.POS_PrintPicture(bm2, nPrintWidth, 1, nCompressMethod);
					}
					if(bmBlackWhite != null)
					{
						pos.POS_PrintPicture(bmBlackWhite, nPrintWidth, 1, nCompressMethod);
					}
					if(bmIu != null)
					{
						pos.POS_PrintPicture(bmIu, nPrintWidth, 0, nCompressMethod);
					}
					if(bmYellowmen != null)
					{
						pos.POS_PrintPicture(bmYellowmen, nPrintWidth, 0, nCompressMethod);
					}
				}
				
				if(bBeeper)
					pos.POS_Beep(1, 5);
				if(bCutter)
					pos.POS_CutPaper();
				if(bDrawer)
					pos.POS_KickDrawer(0, 100);
				
				//int dwTicketIndex = dwWriteIndex++;
				//bPrintResult = pos.POS_TicketSucceed(dwTicketIndex, 30000);
				bPrintResult = pos.GetIO().IsOpened();
			}
			
			return bPrintResult;
		}
	}
	
	public class TaskClose implements Runnable
	{
		BTPrinting bt = null;
		
		public TaskClose(BTPrinting bt)
		{
			this.bt = bt;
		}
		
		@Override
		public void run() {
			// TODO Auto-generated method stub
			bt.Close();
		}
		
	}
	
	@Override
	public void OnOpen() {
		// TODO Auto-generated method stub
		this.runOnUiThread(new Runnable(){

			@Override
			public void run() {
				btnDisconnect.setEnabled(true);
				btnPrint.setEnabled(true);
				btnSearch.setEnabled(false);
				linearlayoutdevices.setEnabled(false);
				for(int i = 0; i < linearlayoutdevices.getChildCount(); ++i)
				{
					Button btn = (Button)linearlayoutdevices.getChildAt(i);
					btn.setEnabled(false);
				}
				Toast.makeText(mActivity, "Connected", Toast.LENGTH_SHORT).show();
			}
		});
	}

	@Override
	public void OnOpenFailed() {
		// TODO Auto-generated method stub
		this.runOnUiThread(new Runnable(){

			@Override
			public void run() {
				btnDisconnect.setEnabled(false);
				btnPrint.setEnabled(false);
				btnSearch.setEnabled(true);
				linearlayoutdevices.setEnabled(true);
				for(int i = 0; i < linearlayoutdevices.getChildCount(); ++i)
				{
					Button btn = (Button)linearlayoutdevices.getChildAt(i);
					btn.setEnabled(true);
				}
				Toast.makeText(mActivity, "Failed", Toast.LENGTH_SHORT).show();
			}
		});
	}
	
	@Override
	public void OnClose() {
		// TODO Auto-generated method stub
		this.runOnUiThread(new Runnable(){

			@Override
			public void run() {
				btnDisconnect.setEnabled(false);
				btnPrint.setEnabled(false);
				btnSearch.setEnabled(true);
				linearlayoutdevices.setEnabled(true);
				for(int i = 0; i < linearlayoutdevices.getChildCount(); ++i)
				{
					Button btn = (Button)linearlayoutdevices.getChildAt(i);
					btn.setEnabled(true);
				}
			}
		});
	}

	/**
	 * 从Assets中读取图片
	 */
	public Bitmap getImageFromAssetsFile(String fileName) {
		Bitmap image = null;
		AssetManager am = getResources().getAssets();
		try {
			InputStream is = am.open(fileName);
			image = BitmapFactory.decodeStream(is);
			is.close();
		} catch (IOException e) {
			e.printStackTrace();
		}

		return image;

	}
	
	public Bitmap getTestImage1(int width, int height)
	{
		Bitmap bitmap = Bitmap.createBitmap(width, height, Config.ARGB_8888);
		Canvas canvas = new Canvas(bitmap);
		Paint paint = new Paint();

		paint.setColor(Color.WHITE);
		canvas.drawRect(0, 0, width, height, paint);
		
		paint.setColor(Color.BLACK);
		for(int i = 0; i < 8; ++i)
		{
			for(int x = i; x < width; x += 8)
			{
				for(int y = i; y < height; y += 8)
				{
					canvas.drawPoint(x, y, paint);
				}
			}
		}
		return bitmap;
	}

	public Bitmap getTestImage2(int width, int height)
	{
		Bitmap bitmap = Bitmap.createBitmap(width, height, Config.ARGB_8888);
		Canvas canvas = new Canvas(bitmap);
		Paint paint = new Paint();

		paint.setColor(Color.WHITE);
		canvas.drawRect(0, 0, width, height, paint);
		
		paint.setColor(Color.BLACK);
		for(int y = 0; y < height; y += 4)
		{
			for(int x = y%32; x < width; x += 32)
			{
				canvas.drawRect(x, y, x+4, y+4, paint);
			}
		}
		return bitmap;
	}
	
	public Bitmap resizeImage(Bitmap bitmap, int w, int h) 
	{
		// load the origial Bitmap
		Bitmap BitmapOrg = bitmap;

		int width = BitmapOrg.getWidth();
		int height = BitmapOrg.getHeight();
		int newWidth = w;
		int newHeight = h;

		// calculate the scale
		float scaleWidth = ((float) newWidth) / width;
		float scaleHeight = ((float) newHeight) / height;

		// create a matrix for the manipulation
		Matrix matrix = new Matrix();
		// resize the Bitmap
		matrix.postScale(scaleWidth, scaleHeight);
		// if you want to rotate the Bitmap
		// matrix.postRotate(45);

		// recreate the new Bitmap
		Bitmap resizedBitmap = Bitmap.createBitmap(BitmapOrg, 0, 0, width,
				height, matrix, true);

		// make a Drawable from Bitmap to allow to set the Bitmap
		// to the ImageView, ImageButton or what ever
		return resizedBitmap;
	}
}
