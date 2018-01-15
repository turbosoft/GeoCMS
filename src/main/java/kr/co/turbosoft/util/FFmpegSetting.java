package kr.co.turbosoft.util;

public class FFmpegSetting {
	
	private String ffmpeg_dir_and_file_name = "C:\\ffmpeg\\bin\\ffmpeg";
	
	public String getFfmpeg_dir_and_file_name() {
		return ffmpeg_dir_and_file_name;
	}
	
	public String getSrc_no_ext(String file_name) {
		file_name = file_name.substring(0, file_name.lastIndexOf("."));
		
		return file_name;
	}
	
	public String getSrc_dir(String file_name) {
		System.out.println("getSrc_dir file name :" +file_name);
		String[] file_name_arr = file_name.split("\\\\");
		
		String file_dir = "";
		for(int i=0; i<file_name_arr.length-1; i++) {
			if(i==file_name_arr.length-2) file_dir += file_name_arr[i];
			else file_dir += file_name_arr[i]+"\\";
		}
		System.out.println("getSrc_dir file_dir :" +file_dir);
		return file_dir;
	}
}
