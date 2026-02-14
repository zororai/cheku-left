package com.lvrenyang.myactivity;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Iterator;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import com.lvrenyang.io.USBPrinting;
import com.lvrenyang.io.IOCallBack;
import com.lvrenyang.io.Pos;
import com.lvrenyang.sample1.R;

import android.annotation.TargetApi;
import android.app.Activity;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Bitmap.Config;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup.LayoutParams;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.Toast;

@TargetApi(Build.VERSION_CODES.HONEYCOMB_MR1)
public class ConnectUSBActivity extends Activity implements OnClickListener, IOCallBack {

	private LinearLayout linearlayoutdevices;

	Button btnDisconnect,btnPrint;
	static ConnectUSBActivity mActivity;
	
	ExecutorService es = Executors.newScheduledThreadPool(30);
	Pos mPos = new Pos();
	USBPrinting mUsb = new USBPrinting();
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_connectusb);

		mActivity = this;
		
		linearlayoutdevices = (LinearLayout) findViewById(R.id.linearlayoutdevices);
		
		btnDisconnect = (Button) findViewById(R.id.buttonDisconnect);
		btnPrint = (Button) findViewById(R.id.buttonPrint);
		btnDisconnect.setOnClickListener(this);
		btnPrint.setOnClickListener(this);
		btnDisconnect.setEnabled(false);
		btnPrint.setEnabled(false);
		
		mPos.Set(mUsb);
		mUsb.SetCallBack(this);
		
		if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB_MR1) {
			probe();
		} else {
			finish();
		}
	}

	@Override
	protected void onDestroy() {
		super.onDestroy();
		btnDisconnect.performClick();
	}

	public void onClick(View arg0) {
		// TODO Auto-generated method stub
		switch (arg0.getId()) {

		case R.id.buttonDisconnect:
			es.submit(new TaskClose(mUsb));
			break;

		case R.id.buttonPrint:
			btnPrint.setEnabled(false);
			es.submit(new TaskPrint(mPos));
			break;
		
		default:
			break;

		}

	}

	private void probe() {
		linearlayoutdevices.removeAllViews();
		final UsbManager mUsbManager = (UsbManager) getSystemService(Context.USB_SERVICE);
				
		HashMap<String, UsbDevice> deviceList = mUsbManager.getDeviceList();
		Iterator<UsbDevice> deviceIterator = deviceList.values().iterator();
		if (deviceList.size() > 0) {
			// 初始化选择对话框布局，并添加按钮和事件

			while (deviceIterator.hasNext()) { // 这里是if不是while，说明我只想支持一种device
				final UsbDevice device = deviceIterator.next();
				//Toast.makeText( this, "" + device.getDeviceId() + device.getDeviceName() + device.toString(), Toast.LENGTH_LONG).show();

				Button btDevice = new Button(
						linearlayoutdevices.getContext());
				btDevice.setLayoutParams(new LayoutParams(
						LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));
				btDevice.setGravity(android.view.Gravity.CENTER_VERTICAL
						| Gravity.LEFT);
				btDevice.setText(String.format(" VID:%04X PID:%04X",
						device.getVendorId(), device.getProductId()));
				btDevice.setOnClickListener(new OnClickListener() {

					public void onClick(View v) {
						// TODO Auto-generated method stub

						PendingIntent mPermissionIntent = PendingIntent
								.getBroadcast(
										ConnectUSBActivity.this,
										0,
										new Intent(
												ConnectUSBActivity.this
														.getApplicationInfo().packageName),
										0);
						
						if (!mUsbManager.hasPermission(device)) {
							mUsbManager.requestPermission(device,
									mPermissionIntent);
							Toast.makeText(getApplicationContext(),
									"没有权限", Toast.LENGTH_LONG)
									.show();
						} else {
							Toast.makeText(mActivity, "Connecting...", Toast.LENGTH_SHORT).show();
							linearlayoutdevices.setEnabled(false);
							for(int i = 0; i < linearlayoutdevices.getChildCount(); ++i)
							{
								Button btn = (Button)linearlayoutdevices.getChildAt(i);
								btn.setEnabled(false);
							}
							btnDisconnect.setEnabled(false);
							btnPrint.setEnabled(false);
							es.submit(new TaskOpen(mUsb,mUsbManager,device));
							//es.submit(new TaskTest(mPos,mUsb,mUsbManager,device));
						}
					}
				});
				linearlayoutdevices.addView(btDevice);
			}
		}
	}

	public class TaskTest implements Runnable
	{
		Pos pos = null;
		USBPrinting usb = null;
		UsbManager usbManager = null;
		UsbDevice usbDevice = null;
		
		public TaskTest(Pos pos, USBPrinting usb, UsbManager usbManager, UsbDevice usbDevice)
		{
			this.pos = pos;
			this.usb = usb;
			this.usbManager = usbManager;
			this.usbDevice = usbDevice;
			pos.Set(usb);
		}
		
		@Override
		public void run() {
			// TODO Auto-generated method stub
			for(int i = 0; i < 1000; ++i)
			{
				long beginTime = System.currentTimeMillis();
				if(usb.Open(usbManager,usbDevice))
				{
					long endTime = System.currentTimeMillis();
					pos.POS_S_Align(0);
					pos.POS_S_TextOut(i+ "\t" + "Open\tUsedTime:" + (endTime - beginTime) + "\r\n", 0, 0, 0, 0, 0);
					beginTime = System.currentTimeMillis();
					boolean ticketResult = pos.POS_TicketSucceed(i, 30000);
					endTime = System.currentTimeMillis();
					pos.POS_S_TextOut(i+ "\t" + "Ticket\tUsedTime:" + (endTime - beginTime) + "\t" + (ticketResult ? "Succeed" : "Failed") +  "\r\n", 0, 0, 0, 0, 0);
					pos.POS_CutPaper();
					usb.Close();
				}
			}
		}
	}

	public class TaskOpen implements Runnable
	{
		USBPrinting usb = null;
		UsbManager usbManager = null;
		UsbDevice usbDevice = null;
		
		public TaskOpen(USBPrinting usb, UsbManager usbManager, UsbDevice usbDevice)
		{
			this.usb = usb;
			this.usbManager = usbManager;
			this.usbDevice = usbDevice;
		}
		
		@Override
		public void run() {
			// TODO Auto-generated method stub
			usb.Open(usbManager,usbDevice);
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
			
			byte[] status = new byte[1];
			if(pos.POS_QueryStatus(status, 3000, 2))
			{
				Bitmap bm1 = mActivity.getTestImage1(nPrintWidth, nPrintWidth);
				Bitmap bm2 = mActivity.getTestImage2(nPrintWidth, nPrintWidth);
				Bitmap bmBlackWhite = getImageFromAssetsFile("blackwhite.png");
				Bitmap bmIu = getImageFromAssetsFile("iu.jpeg");
				Bitmap bmYellowmen = getImageFromAssetsFile("yellowmen.png");
				
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
					//pos.POS_S_SetBarcode("20160618", 0, 72, 3, 60, 0, 2);
					pos.POS_S_SetBarcode("11606211111331200008", 0, 73, 2, 60, 0, 2);
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
				
				int dwTicketIndex = dwWriteIndex++;
				bPrintResult = pos.POS_TicketSucceed(dwTicketIndex, 30000);
			}
			
			return bPrintResult;
		}
	}	
	
	public class TaskClose implements Runnable
	{
		USBPrinting usb = null;
		
		public TaskClose(USBPrinting usb)
		{
			this.usb = usb;
		}
		
		@Override
		public void run() {
			// TODO Auto-generated method stub
			usb.Close();
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
				linearlayoutdevices.setEnabled(true);
				for(int i = 0; i < linearlayoutdevices.getChildCount(); ++i)
				{
					Button btn = (Button)linearlayoutdevices.getChildAt(i);
					btn.setEnabled(true);
				}
				probe(); // 如果因为打印机关机导致Close。那么这里需要重新枚举一下。
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

}