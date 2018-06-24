package kr.co.turbosoft.geocms.util;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.Authenticator;
import java.net.HttpURLConnection;
import java.net.PasswordAuthentication;
import java.net.URL;
import java.net.URLEncoder;
import java.util.ArrayList;

import org.apache.commons.io.FileUtils;
import org.apache.sanselan.ImageReadException;
import org.apache.sanselan.ImageWriteException;
import org.apache.sanselan.Sanselan;
import org.apache.sanselan.common.IImageMetadata;
import org.apache.sanselan.formats.jpeg.JpegImageMetadata;
import org.apache.sanselan.formats.jpeg.exifRewrite.ExifRewriter;
import org.apache.sanselan.formats.tiff.TiffField;
import org.apache.sanselan.formats.tiff.TiffImageMetadata;
import org.apache.sanselan.formats.tiff.constants.ExifTagConstants;
import org.apache.sanselan.formats.tiff.constants.GPSTagConstants;
import org.apache.sanselan.formats.tiff.constants.TagInfo;
import org.apache.sanselan.formats.tiff.constants.TiffConstants;
import org.apache.sanselan.formats.tiff.constants.TiffFieldTypeConstants;
import org.apache.sanselan.formats.tiff.write.TiffOutputDirectory;
import org.apache.sanselan.formats.tiff.write.TiffOutputField;
import org.apache.sanselan.formats.tiff.write.TiffOutputSet;
import org.springframework.stereotype.Controller;

@Controller
public class ExifRW {
	private String fileSavePathStr;
	private String serverUrlStr;
	private String serverIdStr;
	private String serverPassStr;
	private String serverPathStr;
	
	public void exifSettingCon(String fileSavePathStr, String serverUrlStr, String serverIdStr, String serverPassStr, String serverPathStr) {
		this.fileSavePathStr = fileSavePathStr;
        this.serverUrlStr = serverUrlStr;
        this.serverIdStr = serverIdStr;
        this.serverPassStr = serverPassStr;
        this.serverPathStr = serverPathStr;
    }
	
	//EXIF Read
	public String read(String file_full_url, String type, String GeoType, String fileName) {
		File file = new File(fileSavePathStr+ File.separator + GeoType+ File.separator +fileName);
		
		File fileDir = null;
		
		//데이터 저장 변수 선언
		ArrayList<String> name = new ArrayList<String>();
		ArrayList<String> data = new ArrayList<String>();
		
		//EXIF 설정
		IImageMetadata metadata = null;
		
		if(file_full_url != null && !"".equals(file_full_url)){
			
			try {			   
				fileName = URLEncoder.encode(fileName,"utf-8");
				URL gamelan = new URL(file_full_url + "/" + fileName);
				Authenticator.setDefault(new Authenticator()
				{
				  @Override
				  protected PasswordAuthentication getPasswordAuthentication()
				  {
				    return new PasswordAuthentication(serverIdStr, serverPassStr.toCharArray());
				  }
				});
				HttpURLConnection urlConnection = (HttpURLConnection)gamelan.openConnection();
	            urlConnection.connect();
	            
	            fileDir = new File(fileSavePathStr);
				if(!fileDir.isDirectory()){
					fileDir.mkdir();
				}
				fileDir = new File(fileSavePathStr+ File.separator + GeoType);
				if(!fileDir.isDirectory()){
					fileDir.mkdir();
				}
	            
	            FileUtils.copyURLToFile(gamelan, file);
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		
		//EXIF 설정
		if(!fileName.contains(".png") && !fileName.contains(".PNG")){
			try {
				if(file.exists()){
					metadata = Sanselan.getMetadata(file);
					if(file_full_url != null && !"".equals(file_full_url)){
						file.delete();
					}
				}
			}
			catch(Exception e) {
//				e.printStackTrace();
			}
		}
		
		//이름 저장
		if(type.equals("load")) {
			name.add("Make");
			name.add("Model");
			name.add("Data Time");
			name.add("Flash");
			name.add("Shutter Speed Value");
			name.add("Aperture Value");
			name.add("Max Aperture Value");
			name.add("Focal Length");
			name.add("Digital Zoom Ratio");
			name.add("White Balance");
			name.add("Brightness Value");
			name.add("User Comment");
		}
		name.add("GPS Speed");
		name.add("GPS Altitude");
		name.add("GPS Direction");
		name.add("GPS Longitude");
		name.add("GPS Latitude");
		
		if(metadata != null && metadata instanceof JpegImageMetadata) {
			JpegImageMetadata jpegMetadata = (JpegImageMetadata) metadata;
			//일반 정보 + GPS 일부 정보 추출
			TiffField field;
			
			TagInfo[] tagInfo = null;
			if(type.equals("load")) {
				tagInfo = new TagInfo[15];
				tagInfo[0] = TiffConstants.EXIF_TAG_MAKE;
				tagInfo[1] = TiffConstants.EXIF_TAG_MODEL;
				tagInfo[2] = TiffConstants.EXIF_TAG_DATE_TIME_ORIGINAL;
				tagInfo[3] = TiffConstants.EXIF_TAG_FLASH;
				tagInfo[4] = TiffConstants.EXIF_TAG_SHUTTER_SPEED_VALUE;
				tagInfo[5] = TiffConstants.EXIF_TAG_APERTURE_VALUE;
				tagInfo[6] = TiffConstants.EXIF_TAG_MAX_APERTURE_VALUE;
				tagInfo[7] = TiffConstants.EXIF_TAG_FOCAL_LENGTH;
				tagInfo[8] = TiffConstants.EXIF_TAG_DIGITAL_ZOOM_RATIO;
				tagInfo[9] = TiffConstants.EXIF_TAG_WHITE_BALANCE_1;
				tagInfo[10] = TiffConstants.EXIF_TAG_BRIGHTNESS_VALUE;
				tagInfo[11] = TiffConstants.EXIF_TAG_USER_COMMENT;
				tagInfo[12] = TiffConstants.GPS_TAG_GPS_SPEED;
				tagInfo[13] = TiffConstants.GPS_TAG_GPS_ALTITUDE;
				tagInfo[14] = TiffConstants.GPS_TAG_GPS_IMG_DIRECTION;
			}
			else {
				tagInfo = new TagInfo[1];
				tagInfo[0] = TiffConstants.EXIF_TAG_USER_COMMENT;
			}
			
			for(int i=0; i<tagInfo.length; i++) {
				field = jpegMetadata.findEXIFValue(tagInfo[i]);
				if(field == null) data.add("Not Found.");
				else {
					data.add(field.getValueDescription());
				}
			}
			
			//GPS Lon, Lat 정보 추출
			TiffImageMetadata exifMetadata = jpegMetadata.getExif();
			if(exifMetadata != null) {
				try {
					TiffImageMetadata.GPSInfo gpsInfo = exifMetadata.getGPS();
					if(null != gpsInfo) {
						double lon = gpsInfo.getLongitudeAsDegreesEast();
						double lat = gpsInfo.getLatitudeAsDegreesNorth();
						
						data.add(lon+"");
						data.add(lat+"");
					}
					else {
						data.add("Not Found.");
						data.add("Not Found.");
					}
				} catch(ImageReadException e) { e.printStackTrace(); }
			}
			else {
				data.add("Not Found.");
				data.add("Not Found.");
			}
		}else {
			for(int i=0; i<name.size(); i++) {
				data.add("Not Found.");
			}
		}
		
		String result = "";

		//추출 정보 재설정
		for(int i=0; i<name.size(); i++) {
			if(i==name.size()-1) result += name.get(i) + "<Separator>" + data.get(i);
			else result += name.get(i) + "<Separator>" + data.get(i) + "<LineSeparator>";
		}
		//정보 리턴
		return result;
	}
	
	//EXIF Data Parse
	public String[] parseData(String data) {
		String[] buf = data.split("<LineSeparator>");
		String[] split_data = new String[6];
		
		split_data[0] = buf[0];
		split_data[1] = buf[1];
		split_data[2] = buf[2];
		split_data[3] = buf[3];
//		split_data[4] = buf[4];

		System.out.println(split_data[0]+", "+split_data[1]+", "+split_data[2]+", "+split_data[3]);
		
		return split_data;
	}
	
	//EXIF Write
	public void write(String file_name, String[] data) {
		/*
		 * data[0] = user_comment
		 * data[1] = GPS Direction
		 * data[2] = GPS Longitude
		 * data[3] = GPS Latitude
		 */
		String user_comment = "";
		String gps_direction = "";
		String gps_lon = "";
		String gps_lat = "";
		String gps_alt = "";
		String gps_speed = "";
		
		if(data[0].length()>0 && !data[0].equals("<NONE>")) user_comment = data[0];
		if(data[1].length()>0 && !data[1].equals("<NONE>")) gps_direction = data[1];
		if(data[2].length()>0 && !data[2].equals("<NONE>")) gps_lon = data[2];
		if(data[3].length()>0 && !data[3].equals("<NONE>")) gps_lat = data[3];
//		if(data[4].length()>0 && !data[4].equals("<NONE>")) gps_speed = data[4];
		
		//user_comment 의 길이를 설정 (한글이 포함되었을 경우 +2 아닐경우 +1)
		byte[] user_comment_byte = user_comment.getBytes();
		int user_comment_len = 0;
		for(int i=0; i<user_comment_byte.length;) {
			if((user_comment_byte[i] & 0x80) == 0x80) {
				++i;
				user_comment_len += 2;
			}
			else { user_comment_len += 1; }
			++i;
		}
		
		File file = new File(fileSavePathStr+"/"+"tmp.jpg");
		
		//EXIF Write 설정
		File dst = null;
		IImageMetadata metadata = null;
		JpegImageMetadata jpegMetadata = null;
		TiffImageMetadata exif = null;
		OutputStream os = null;
		TiffOutputSet outputSet = new TiffOutputSet();
		
		try { metadata = Sanselan.getMetadata(file); }
		catch(ImageReadException e) { e.printStackTrace(); }
		catch(IOException e) { e.printStackTrace(); }
		
		if(metadata != null) { jpegMetadata = (JpegImageMetadata) metadata;	}
		if(jpegMetadata != null) { exif = jpegMetadata.getExif(); }
		if(exif != null) {
			try {outputSet = exif.getOutputSet(); }
			catch(ImageWriteException e) { e.printStackTrace(); }
		}
		if(outputSet != null) {
			try {
				TiffOutputDirectory exifDirectory = outputSet.getOrCreateExifDirectory();
				
				//User Comment 삽입
				TiffOutputField imageCommentPre = outputSet.findField(TiffConstants.EXIF_TAG_USER_COMMENT);
				if(imageCommentPre != null) { outputSet.removeField(TiffConstants.EXIF_TAG_USER_COMMENT); }
				
				TiffOutputField imageComment;
				imageComment = new TiffOutputField(
						ExifTagConstants.EXIF_TAG_USER_COMMENT,
						TiffFieldTypeConstants.FIELD_TYPE_ASCII,
						user_comment_len,
						user_comment.getBytes()
						);
				exifDirectory.add(imageComment);
				
				//GPS Direction 삽입
				TiffOutputField imageDirectionPre = outputSet.findField(TiffConstants.GPS_TAG_GPS_IMG_DIRECTION);
				if(imageDirectionPre != null) { outputSet.removeField(TiffConstants.GPS_TAG_GPS_IMG_DIRECTION); }
				
				TiffOutputField imageDirection;
				imageDirection = new TiffOutputField(
						GPSTagConstants.GPS_TAG_GPS_IMG_DIRECTION,
						TiffFieldTypeConstants.FIELD_TYPE_ASCII,
						gps_direction.length(),
						gps_direction.getBytes()
						);
				exifDirectory.add(imageDirection);
				
				//GPS Longitude, Latitude 삽입
				if(gps_lon.length()>0 && gps_lat.length()>0) {
					double lon = Double.parseDouble(gps_lon);
					double lat = Double.parseDouble(gps_lat);
					outputSet.setGPSInDegrees(lon, lat);
				}
				
				//GPS ALT 삽입
//				TiffOutputField imageAlt = outputSet.findField(TiffConstants.GPS_TAG_GPS_ALTITUDE);
//				if(imageAlt != null) { outputSet.removeField(TiffConstants.GPS_TAG_GPS_ALTITUDE); }
//				
//				TiffOutputField imageAltiStr;
//				imageAltiStr = new TiffOutputField(
//						GPSTagConstants.GPS_TAG_GPS_ALTITUDE,
//						TiffFieldTypeConstants.FIELD_TYPE_ASCII,
//						gps_alt.length(),
//						gps_alt.getBytes()
//						);
//				exifDirectory.add(imageAltiStr);
				
				//focal 삽입
//				TiffOutputField imageFocal = outputSet.findField(TiffConstants.EXIF_TAG_FOCAL_LENGTH);
//				if(imageFocal != null) { outputSet.removeField(TiffConstants.EXIF_TAG_FOCAL_LENGTH); }
//				
//				TiffOutputField imageFocalStr;
//				imageFocalStr = new TiffOutputField(
//						TiffConstants.EXIF_TAG_FOCAL_LENGTH,
//						TiffFieldTypeConstants.FIELD_TYPE_ASCII,
//						gps_speed.length(),
//						gps_speed.getBytes()
//						);
//				exifDirectory.add(imageFocalStr);
				
			}
			catch(ImageWriteException e) { e.printStackTrace(); }
		}
		//임시 파일 생성
		try {
			dst = File.createTempFile("temp-"+System.currentTimeMillis(), ".jpeg");
			os = new FileOutputStream(dst);
			os = new BufferedOutputStream(os);
		} catch(IOException e) { e.printStackTrace(); }
		
		try { new ExifRewriter().updateExifMetadataLossless(file, os, outputSet); }
		catch(ImageReadException e) { e.printStackTrace(); }
		catch(ImageWriteException e) { e.printStackTrace(); }
		catch(IOException e) { e.printStackTrace(); }
		finally { 
			if(os != null) {
				try { os.close(); }
				catch(IOException e) { e.printStackTrace(); }
			}
		}
		//파일 복사
		try { FileUtils.copyFile(dst, file); }
		catch(IOException e) { e.printStackTrace(); }
	}
	
	//EXIF Write
	public void write(String file_name, String user_comment) {
		//user_comment 의 길이를 설정 (한글이 포함되었을 경우 +2 아닐경우 +1)
		byte[] user_comment_byte = user_comment.getBytes();
		int user_comment_len = 0;
		for(int i=0; i<user_comment_byte.length;) {
			if((user_comment_byte[i] & 0x80) == 0x80) {
				++i;
				user_comment_len += 2;
			}
			else { user_comment_len += 1; }
			++i;
		}
		
		//EXIF Write 설정
		File file = new File(file_name);
		File dst = null;
		IImageMetadata metadata = null;
		JpegImageMetadata jpegMetadata = null;
		TiffImageMetadata exif = null;
		OutputStream os = null;
		TiffOutputSet outputSet = new TiffOutputSet();
		
		try { metadata = Sanselan.getMetadata(file); }
		catch(ImageReadException e) { e.printStackTrace(); }
		catch(IOException e) { e.printStackTrace(); }
		
		if(metadata != null) { jpegMetadata = (JpegImageMetadata) metadata;	}
		if(jpegMetadata != null) { exif = jpegMetadata.getExif(); }
		if(exif != null) {
			try {outputSet = exif.getOutputSet(); }
			catch(ImageWriteException e) { e.printStackTrace(); }
		}
		if(outputSet != null) {
			TiffOutputField imageCommentPre = outputSet.findField(TiffConstants.EXIF_TAG_USER_COMMENT);
			if(imageCommentPre != null) { outputSet.removeField(TiffConstants.EXIF_TAG_USER_COMMENT); }
			//Field 삽입
			try {
				TiffOutputField imageComment;
				imageComment = new TiffOutputField(
						ExifTagConstants.EXIF_TAG_USER_COMMENT,
						TiffFieldTypeConstants.FIELD_TYPE_ASCII,
						user_comment_len,
						user_comment.getBytes()
						);
				
				TiffOutputDirectory exifDirectory = outputSet.getOrCreateExifDirectory();
				exifDirectory.add(imageComment);
			}
			catch(ImageWriteException e) { e.printStackTrace(); }
		}
		//임시 파일 생성
		try {
			dst = File.createTempFile("temp-"+System.currentTimeMillis(), ".jpeg");
			os = new FileOutputStream(dst);
			os = new BufferedOutputStream(os);
		} catch(IOException e) { e.printStackTrace(); }
		
		try { new ExifRewriter().updateExifMetadataLossless(file, os, outputSet); }
		catch(ImageReadException e) { e.printStackTrace(); }
		catch(ImageWriteException e) { e.printStackTrace(); }
		catch(IOException e) { e.printStackTrace(); }
		finally { 
			if(os != null) {
				try { os.close(); }
				catch(IOException e) { e.printStackTrace(); }
			}
		}
		//파일 복사
		try { FileUtils.copyFile(dst, file); }
		catch(IOException e) { e.printStackTrace(); }
	}
}
