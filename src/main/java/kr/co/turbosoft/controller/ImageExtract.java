package kr.co.turbosoft.geocms.util;

public class ImageExtract {
	
	//썸네일 이미지 추출
	public void ImageExtractor(String file_name) {
		FFmpegSetting ffmpegSetting = new FFmpegSetting();
		
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
}
