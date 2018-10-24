package kr.co.turbosoft.geocms.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;

public class SearchXML {
	public ArrayList<String> getSearchList(String dir, String text) {
		
		System.out.println("dir : "+dir);
		File file = new File(dir);
		String files[] = file.list();
		
		String[] buf1, buf2;
		ArrayList<String> type_arr = new ArrayList<String>();
		ArrayList<String> filename_arr = new ArrayList<String>();
		
		for(int i=0; i<files.length-1; i++) {
			buf1 = files[i].split("\\.");
			buf2 = files[i+1].split("\\.");
			if(buf1[0].equals(buf2[0])) {
				if(buf2[1].equals("xml")) {
					if(buf1[1].toLowerCase().equals("jpg") || buf1[1].toLowerCase().equals("gif") || buf1[1].toLowerCase().equals("png") || buf1[1].toLowerCase().equals("bmp")) {
						type_arr.add("image");
						filename_arr.add(files[i+1]);
					}
					else if(buf1[1].toLowerCase().equals("mp4")) {
						type_arr.add("video");
						filename_arr.add(files[i+1]);
					}
					else {}
				}
			}
		}
		
		ArrayList<String> findFileName = new ArrayList<String>();
		for(int i=0; i<filename_arr.size(); i++) {
			try {
				BufferedReader in = new BufferedReader(new InputStreamReader(new FileInputStream(dir+File.separator+filename_arr.get(i)),"UTF8"));  //FileReader�� �ü���� �⺻ �ѱ� ���ڵ��� �⺻���� �ν��ϱ� ������ ����
				String s;
				while((s=in.readLine())!=null) {
					if(s.indexOf(text)!=-1) findFileName.add(dir+File.separator+filename_arr.get(i).split("\\.")[0]+"@"+type_arr.get(i));
				}
			} catch (IOException e) { e.printStackTrace(); }
		}
		
		return findFileName;
	}
}
