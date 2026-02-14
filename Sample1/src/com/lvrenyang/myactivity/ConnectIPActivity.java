package com.lvrenyang.myactivity;

import java.io.IOException;
import java.io.InputStream;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import com.lvrenyang.io.IOCallBack;
import com.lvrenyang.io.NETPrinting;
import com.lvrenyang.io.Pos;
import com.lvrenyang.sample1.R;

import android.app.Activity;
import android.content.Context;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

public class ConnectIPActivity extends Activity implements OnClickListener, IOCallBack {

	//private static final String TAG = "ConnectIPActivity";
	
	ExecutorService es = Executors.newScheduledThreadPool(30);
	Pos mPos = new Pos();
	NETPrinting mNet = new NETPrinting();
	
	EditText inputIp, inputPort;
	Button btnConnect,btnDisconnect,btnPrint;
	
	ConnectIPActivity mActivity;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_connectip);
		
		mActivity = this;
		
		btnConnect = (Button) findViewById(R.id.buttonConnect);
		btnDisconnect = (Button) findViewById(R.id.buttonDisconnect);
		btnPrint = (Button) findViewById(R.id.buttonPrint);
		inputIp = (EditText) findViewById(R.id.editTextInputIp);
		inputPort = (EditText) findViewById(R.id.editTextInputPort);

		btnConnect.setOnClickListener(this);
		btnDisconnect.setOnClickListener(this);
		btnPrint.setOnClickListener(this);
		
		inputIp.setText("192.168.1.80");
		inputPort.setText("9100");
		btnConnect.setEnabled(true);
		btnDisconnect.setEnabled(false);
		btnPrint.setEnabled(false);
		
		mPos.Set(mNet);
		mNet.SetCallBack(this);
		
		getWindow().setFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
	}

	@Override
	protected void onDestroy() {
		super.onDestroy();
		btnDisconnect.performClick();
	}

	public void onClick(View arg0) {
		// TODO Auto-generated method stub
		switch (arg0.getId()) {

		case R.id.buttonConnect:
			boolean valid = false;
			int port = 9100;
			String ip = "";
			try {
				ip = inputIp.getText().toString();
				if (null == IsIPValid(ip))
					throw new Exception("Invalid IP Address");
				port = Integer.parseInt(inputPort.getText().toString());
				valid = true;
			} catch (NumberFormatException e) {
				Toast.makeText(this, "Invalid Port Number", Toast.LENGTH_LONG)
						.show();
				valid = false;
			} catch (Exception e) {
				Toast.makeText(this, "Invalid IP Address", Toast.LENGTH_LONG)
						.show();
				valid = false;
			}
			if (valid) {
				// 进行下一步连接操作。
				Toast.makeText(this, "Connecting...", Toast.LENGTH_SHORT).show();
				btnConnect.setEnabled(false);
				btnDisconnect.setEnabled(false);
				btnPrint.setEnabled(false);
				es.submit(new TaskOpen(mNet,ip,port,mActivity));
			}
			break;

		case R.id.buttonDisconnect:
			es.submit(new TaskClose(mNet));
			break;

		case R.id.buttonPrint:
			btnPrint.setEnabled(false);
			es.submit(new TaskPrint(mPos));
			break;
			
		}
	}
	
	public static byte[] IsIPValid(String ip)
	{
		byte[] ipbytes = new byte[4];
		int valid = 0;
		int s,e;
		String ipstr = ip + ".";
		s = 0;
		for(e = 0; e < ipstr.length(); e++)
		{
			if ('.' == ipstr.charAt(e))
			{
				if ((e - s > 3) || (e - s) <= 0)	// 最长3个字符
					return null;
				
				int ipbyte = -1;
				try{
					ipbyte = Integer.parseInt(ipstr.substring(s, e));
					if (ipbyte < 0 || ipbyte > 255)
						return null;
					else
						ipbytes[valid] = (byte) ipbyte;
				}
				catch(NumberFormatException exce)
				{
					return null;
				}
				s = e + 1;
				valid++;
			}
		}
		if (valid == 4)
			return ipbytes;
		else
			return null;
	}
	
	public class TaskOpen implements Runnable
	{
		NETPrinting net = null;
		String ip = null;
		int port;
		Context context;
		
		public TaskOpen(NETPrinting net, String ip, int port, Context context)
		{
			this.net = net;
			this.ip = ip;
			this.port = port;
			this.context = context;
		}
		
		@Override
		public void run() {
			// TODO Auto-generated method stub
			net.Open(ip, port, context);
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
				
				int dwTicketIndex = dwWriteIndex++;
				bPrintResult = pos.POS_TicketSucceed(dwTicketIndex, 30000);
			}
			
			return bPrintResult;
		}
	}	
	
	public class TaskClose implements Runnable
	{
		NETPrinting net = null;
		
		public TaskClose(NETPrinting net)
		{
			this.net = net;
		}
		
		@Override
		public void run() {
			// TODO Auto-generated method stub
			net.Close();
		}
		
	}

	@Override
	public void OnOpen() {
		// TODO Auto-generated method stub
		this.runOnUiThread(new Runnable(){

			@Override
			public void run() {
				btnConnect.setEnabled(false);
				btnDisconnect.setEnabled(true);
				btnPrint.setEnabled(true);
			}
		});
	}

	@Override
	public void OnOpenFailed() {
		// TODO Auto-generated method stub
		this.runOnUiThread(new Runnable(){

			@Override
			public void run() {
				btnConnect.setEnabled(true);
				btnDisconnect.setEnabled(false);
				btnPrint.setEnabled(false);
			}
		});
	}
	
	@Override
	public void OnClose() {
		// TODO Auto-generated method stub
		this.runOnUiThread(new Runnable(){

			@Override
			public void run() {
				btnConnect.setEnabled(true);
				btnDisconnect.setEnabled(false);
				btnPrint.setEnabled(false);
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