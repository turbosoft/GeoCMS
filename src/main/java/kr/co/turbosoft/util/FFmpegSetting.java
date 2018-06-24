package kr.co.turbosoft.geocms.util;

public class FFmpegSetting {
	
	private String ffmpeg_dir_and_file_name = "C:\\ffmpeg\\bin\\ffmpeg";
	
	public String getFfmpeg_dir_and_file_name() {
		return ffmpeg_dir_and_file_name;
	}
	
	public String getSrc_no_ext(String file_name) {
		file_name = file_name.replace("\\", "\\\\");
		
		file_name = file_name.substring(0, file_name.length()-4);
		
		return file_name;
	}
	
	public String getSrc_dir(String file_name) {
		String[] file_name_arr = file_name.split("\\\\");
		
		String file_dir = "";
		for(int i=0; i<file_name_arr.length-1; i++) {
			if(i==file_name_arr.length-2) file_dir += file_name_arr[i];
			else file_dir += file_name_arr[i]+"\\\\";
		}
		
		return file_dir;
	}
}
