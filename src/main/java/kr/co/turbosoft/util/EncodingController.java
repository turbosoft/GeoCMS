package kr.co.turbosoft.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.net.ftp.FTP;
import org.apache.commons.net.ftp.FTPClient;
import org.apache.commons.net.ftp.FTPReply;

import kr.co.turbosoft.dao.DataDao;
import kr.co.turbosoft.util.ImageExtract;
import kr.co.turbosoft.util.VideoEncoding;

public class EncodingController extends Thread{
	private DataDao dataDao = null;
	private String loginId;
	private String logKey;
	private List<Map<String, Object>> fileNameList;
	
	private String saveUserPath;
	private String serverUrlStr;
	private String userIdStr;
	private String userPassStr;
	private String portNumStr;
	private String saveFilePathStr;
	
	public void setDataAPI(DataDao dataDao){
		this.dataDao = dataDao;
	}
	
	public EncodingController(String loginId, String logKey, List<Map<String, Object>> fileNameList,
			String saveUserPath, String serverUrlStr, String userIdStr, String userPassStr, String portNumStr, String saveFilePathStr) {
        this.loginId = loginId;
        this.logKey = logKey;
        this.fileNameList = fileNameList;
        this.saveUserPath = saveUserPath;
        this.serverUrlStr = serverUrlStr;
        this.userIdStr = userIdStr;
        this.userPassStr = userPassStr;
        this.portNumStr = portNumStr;
        this.saveFilePathStr = saveFilePathStr;
    }
	
	@Override
	public void run() {
        System.out.println("thread run.");
		
        List<Object> removeList = new ArrayList<Object>();
        Map<String, Object> fileNameMap = new HashMap<String, Object>();
		HashMap<String, String> param = new HashMap<String, String>();
		HashMap<String, Object> objParam = new HashMap<String, Object>();
		ArrayList<Object> resIdx = new ArrayList<Object>();
		String fileNameStr = "";
		
		File userTempDir = new File(saveUserPath+File.separator+"GeoVideo"+File.separator+ loginId +"_"+ logKey);
		
		param.put("loginId", loginId);
		param.put("idx", logKey);
		
		ImageExtract imageExtract = new ImageExtract();
		VideoEncoding videoEncoding = new VideoEncoding();
		String uploadType = "GeoVideo";
		FTPClient ftp = null; // FTP Client 객체 
		FileInputStream fis = null; // File Input Stream 
		int reply = 0;
		String thumFile = "";
		String oggFile = "";
		String gpxFile = "";
		String gpxModifyFile = "";
		List<String> tmpFileList = new ArrayList<String>();
		String ftpfileName = "";
		boolean isSuccess = false;
		
		if(fileNameList != null && fileNameList.size() > 0){
			try{
				for(Map<String, Object> tmpFileMap : fileNameList){
					fileNameStr = String.valueOf(tmpFileMap.get("file"));
					//이미지 추출
					imageExtract.ImageExtractor(fileNameStr);
					
					//자동 인코딩 (1차 : ogg)
					int resEncoding = videoEncoding.convertToOgg(fileNameStr);
					System.out.println("resEncoding : " + resEncoding);
					if(resEncoding != 1){
						ftpError(param);
						return;
					}
				}
				
				ftp = new FTPClient(); // FTP Client 객체 생성 
				ftp.setControlEncoding("UTF-8"); // 문자 코드를 UTF-8로 인코딩 
				ftp.connect(serverUrlStr, Integer.parseInt(portNumStr)); // 서버접속 " "안에 서버 주소 입력 또는 "서버주소", 포트번호 
				
				reply = ftp.getReplyCode();//
				if(!FTPReply.isPositiveCompletion(reply)) {
					ftp.disconnect();
					ftpError(param);
					return;
			    }
				
				if(!ftp.login(userIdStr, userPassStr)) {
					ftp.logout();
					ftpError(param);
					return;
			    }
				
				ftp.setFileType(FTP.BINARY_FILE_TYPE);
				ftp.enterLocalPassiveMode();
			    

			    ftp.changeWorkingDirectory(saveFilePathStr+"/"+uploadType); // 작업 디렉토리 변경
			    reply = ftp.getReplyCode();
			    if (reply == 550) {
			    	ftp.makeDirectory(saveFilePathStr+"/"+uploadType);
			    	reply = ftp.getReplyCode();
			    	if (reply == 550) {
			    		ftpError(param);
						return;
			    	}
			    	ftp.changeWorkingDirectory(saveFilePathStr+"/"+uploadType); // 작업 디렉토리 변경
			    	reply = ftp.getReplyCode();
			    	if (reply == 550) {
			    		ftpError(param);
						return;
			    	}
			    }
			    System.out.println("fileNameStrCnt ");
			    int fileNameStrCnt = 0;
			    File checkFile = null;
			    File checkFile2 = null;
			    for(Map<String, Object> tmpFileMap : fileNameList){
			    	fileNameStr = "";
			    	thumFile = "";
			    	oggFile = "";
			    	gpxFile = "";
			    	gpxModifyFile = "";
			    	ftpfileName = "";
			    	isSuccess = false;
			    	
			    	try{
			    		fileNameStr = String.valueOf(tmpFileMap.get("file"));
			    		thumFile = fileNameStr.substring(0,fileNameStr.lastIndexOf(".")) + "_thumb.jpg";
			    		oggFile = fileNameStr.substring(0,fileNameStr.lastIndexOf(".")) + "_ogg.ogg";
			    		gpxFile = fileNameStr.substring(0,fileNameStr.lastIndexOf(".")) + "_ogg.gpx";
			    		gpxModifyFile = fileNameStr.substring(0,fileNameStr.lastIndexOf(".")) + "_ogg_modify.gpx";
			    		tmpFileList = new ArrayList<String>();
			    		tmpFileList.add(thumFile);
			    		tmpFileList.add(oggFile);
			    		tmpFileList.add(gpxFile);
			    		tmpFileList.add(gpxModifyFile);
			    		
			    		for(int k=0; k<tmpFileList.size();k++){
			    			if(k < 2 || fileNameStrCnt == 0 && k == 2  || k == 3){
			    				if(fileNameStrCnt == 0 && k == 2){
			    					fileNameStrCnt = 1;
			    					checkFile = new File(tmpFileList.get(k));
			    					if(!checkFile.exists()){
			    						continue;
			    					}
			    				};
			    				
			    				if(k == 3){
			    					checkFile2 = new File(tmpFileList.get(k));
			    					if(!checkFile2.exists()){
			    						continue;
			    					}
			    				}
			    				
			    				fis = new FileInputStream(tmpFileList.get(k));
			    				if(fis != null){
//			    					ftpfileName = tmpFileList.get(k).substring(tmpFileList.get(k).lastIndexOf("\\")+1);	//git
			    					ftpfileName = tmpFileList.get(k).substring(tmpFileList.get(k).lastIndexOf(File.separator)+1);	//linux
								    isSuccess = ftp.storeFile(ftpfileName, fis);
								    
								    if(k == 1){
								    	checkFile = new File(tmpFileList.get(2));
				    					if(!checkFile.exists()){
				    						if(isSuccess) {
												resIdx = new ArrayList<Object>();
												resIdx.add(tmpFileMap.get("idx"));
												objParam.clear();
												objParam.put("fileIdxs", resIdx);
												objParam.put("status", "COMPLETE");
											    dataDao.updateContentChildStatus(objParam);
										    	System.out.println(tmpFileList.get(k) + "파일 FTP 업로드 성공");
										    }
				    					}
								    }else if(k == 2){
								    	if(isSuccess) {
											resIdx = new ArrayList<Object>();
											resIdx.add(tmpFileMap.get("idx"));
											objParam.clear();
											objParam.put("fileIdxs", resIdx);
											objParam.put("status", "COMPLETE");
										    dataDao.updateContentChildStatus(objParam);
									    	System.out.println(tmpFileList.get(k) + "파일 FTP 업로드 성공");
									    }
								    }
			    				}
			    			}
			    		}
					} catch(IOException ie) {
						ie.printStackTrace(); 
						ftpError(param);
						return;
					} finally {
						if(fis != null) {
							try {
								fis.close();
							} catch(IOException ie) {
								ie.printStackTrace();
								ftpError(param);
								return;
							}
						}
					}
			    }
			    param.put("status", "COMPLETE");
		    	dataDao.updateLog(param);
		    	
				
			}catch(Exception e){
				e.printStackTrace();
				ftpError(param);
			}finally{
				if(userTempDir.exists()){
			    	File[] contents = userTempDir.listFiles();
			    	if (contents != null) {
			            for (File f : contents) {
			            	f.delete();
			            }
			        }
					userTempDir.delete();
				}
			}
		}
    }
	
	public void ftpError(HashMap<String, String> param){
		List<Object> removeList = new ArrayList<Object>();
		Map<String, Object> fileNameMap = new HashMap<String, Object>();
		File userTempDir = new File(saveUserPath+File.separator+"GeoVideo"+File.separator+ loginId +"_"+ logKey);
		HashMap<String, Object> objParam = new HashMap<String, Object>();
		
		param.put("status", "ERROR");
		dataDao.updateLog(param);
		
	    for(int m=0;m<fileNameList.size();m++){
	    	fileNameMap = fileNameList.get(m);
	    	removeList.add(fileNameMap.get("idx"));
	    }
	    
	    objParam.put("fileIdxs", removeList);
	    objParam.put("status", "ERROR");
	    dataDao.updateContentChildStatus(objParam);
	    
	    if(userTempDir.exists()){
	    	File[] contents = userTempDir.listFiles();
	    	if (contents != null) {
	            for (File f : contents) {
	            	f.delete();
	            }
	        }
			userTempDir.delete();
		}
	}
}
