package kr.co.turbosoft.geocms.util;

public class VideoEncoding {
	
	//동영상 인코딩
	public void convertToOgg(String file_name) {
		FFmpegSetting ffmpegSetting = new FFmpegSetting();
		
		String[] message = new String[] {
				ffmpegSetting.getFfmpeg_dir_and_file_name(),
				"-i",
				file_name,
				ffmpegSetting.getSrc_no_ext(file_name)+"_mp4.mp4"
		};
		
		FFmpeg ffmpeg = new FFmpeg();
		String value = ffmpeg.runFFmpeg(file_name, ffmpegSetting.getSrc_dir(file_name), message, "encoding");
		System.out.println("종료 정보 : "+value);
	}
}
