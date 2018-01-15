package kr.co.turbosoft.util;

import java.util.List;

import kr.co.turbosoft.util.FFmpeg;
import kr.co.turbosoft.util.FFmpegSetting;

public class ImageExtract {
	
	//썸네일 이미지 추출
	public void ImageExtractor(String file_name) {
		FFmpegSetting ffmpegSetting = new FFmpegSetting();
		String osName = System.getProperty("os.name").toLowerCase();
		String osffmpeg = "";
		
		if(osName.indexOf("win") >= 0){
			osffmpeg = "win";
		}else if(osName.indexOf("mac") >= 0){
			osffmpeg = "mac";
		}else if(osName.indexOf("nix") >= 0 || osName.indexOf("nux") >= 0 || osName.indexOf("aix") > 0 ){
			osffmpeg = "linux";
		}else if(osName.indexOf("sunos") >= 0){
			osffmpeg = "sunos";
		}

		if(osffmpeg != null && !"".equals(osffmpeg)){
			if("win".equals(osffmpeg))
			{
				String[] message = new String[] { 
					ffmpegSetting.getFfmpeg_dir_and_file_name(),
					"-i",
					file_name,
					"-an",
					"-ss",
					"00:00:01",
					"-r",
					"1",
					"-vframes",
					"1",
					"-y",
					ffmpegSetting.getSrc_no_ext(file_name)+"_thumb.jpg"
				};
		
				FFmpeg ffmpeg = new FFmpeg();
				ffmpeg.runFFmpeg(file_name, ffmpegSetting.getSrc_dir(file_name), message, "thumb");
			}
			else if("linux".equals(osffmpeg))
			{
				String dirPath = file_name.substring(0,file_name.lastIndexOf("/upload/GeoVideo")) + "/ffmpeg/bin/ffmpeg";
				System.out.println("ImageExtractor : " + file_name);
				System.out.println("ImageExtractor dirPath : " + dirPath);
				String[] message = new String[] { 
					"ffmpeg",
					"-i",
					file_name,
					"-an",
					"-ss",
					"00:00:01",
					"-r",
					"1",
					"-vframes",
					"1",
					"-y",
					ffmpegSetting.getSrc_no_ext(file_name)+"_thumb.jpg"
				};
				
				FFmpeg ffmpeg = new FFmpeg();
				ffmpeg.runFFmpeg_linux(file_name, dirPath, message, "thumb");
			}
		}
		
	}	
}
