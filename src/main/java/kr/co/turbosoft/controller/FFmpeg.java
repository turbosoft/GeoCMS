package kr.co.turbosoft.geocms.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

public class FFmpeg {
	//Run FFmpeg
	public String runFFmpeg(String file_name, String src_file_root_dir, String[] message, String type) {
		
		File origin_file = null;
		if(type.equals("encoding")) {
			origin_file = new File(file_name);
		}
		System.out.println("runFFmpeg:"+file_name + ":"+ src_file_root_dir +":"+ message + ":" +type);
		ProcessBuilder processBuilder = new ProcessBuilder(message);
		
		processBuilder.redirectErrorStream(true);
		processBuilder.directory(new File(src_file_root_dir));
		
		Process process = null;
		
		try {
			process = processBuilder.start();
		} catch (Exception e) {
			e.printStackTrace();
			process.destroy();
			
			return null;
		}
		
		cleanInputStream(process.getInputStream());
		
		try {
			process.waitFor();
		} catch (InterruptedException e) {
			e.printStackTrace();
			process.destroy();
		}
		
		if(type.equals("encoding"))	origin_file.delete();
		
		return "Converting Complete";
	}
	//인풋 스트림 제거
	private void cleanInputStream(final InputStream is) {
		new Thread() {
			public void run() {
				try {
					BufferedReader br = new BufferedReader(new InputStreamReader(is));
					String cmd;
					while((cmd = br.readLine()) != null) {
						System.out.println("cmd:"+cmd);
					}
				} catch(IOException e) {
					e.printStackTrace();
				}
			}
		}.start();
	}
}
