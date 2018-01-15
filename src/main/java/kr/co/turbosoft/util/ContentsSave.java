package kr.co.turbosoft.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.Date;
import java.util.Iterator;

import javax.imageio.ImageIO;
import javax.imageio.ImageReader;
import javax.imageio.metadata.IIOMetadata;
import javax.imageio.stream.ImageInputStream;

import org.apache.sanselan.ImageReadException;
import org.apache.sanselan.Sanselan;
import org.apache.sanselan.common.IImageMetadata;
import org.apache.sanselan.formats.jpeg.JpegImageMetadata;
import org.apache.sanselan.formats.tiff.TiffField;
import org.apache.sanselan.formats.tiff.TiffImageMetadata;
import org.apache.sanselan.formats.tiff.constants.TiffTagConstants;
import org.apache.taglibs.standard.extra.spath.Path;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;

import com.drew.imaging.ImageMetadataReader;
import com.drew.imaging.ImageProcessingException;
import com.drew.imaging.jpeg.JpegMetadataReader;
import com.drew.metadata.Directory;
import com.drew.metadata.Metadata;
import com.drew.metadata.Tag;
import org.apache.commons.lang.StringUtils;

public class ContentsSave {
	public String saveImageContent(String setFiles) {
		
		double lati = 0;
		double longi = 0;
		long fileDate = 0;
		
		File file = new File(setFiles);
		//exif설정
		IImageMetadata metadata = null;
		try { metadata = Sanselan.getMetadata(file); }
		catch(ImageReadException e) { e.printStackTrace(); }
		catch(IOException e) { e.printStackTrace(); }
        
		if(metadata != null){
			JpegImageMetadata jpegMetadata = (JpegImageMetadata) metadata;
			if(jpegMetadata != null){	
				TiffImageMetadata exifMetadata = jpegMetadata.getExif();
				
				if(exifMetadata != null) {
					try {
						TiffImageMetadata.GPSInfo gpsInfo = exifMetadata.getGPS();
						if(null != gpsInfo) {
							
							
							longi = gpsInfo.getLongitudeAsDegreesEast();
							lati = gpsInfo.getLatitudeAsDegreesNorth();
						}
					} catch(ImageReadException e) { e.printStackTrace(); }
				}
			}	
		}
		
		String resultData = String.valueOf(longi);
		resultData += ","+ String.valueOf(lati);
		return resultData;
	}
        
        void displayMetadata(Node root) {
            displayMetadata(root, 0);
        }

        void indent(int level) {
            for (int i = 0; i < level; i++)
                System.out.print("    ");
        }
        
        void displayMetadata(Node node, int level) {
            // print open tag of element
            indent(level);
            System.out.print("<" + node.getNodeName());
            NamedNodeMap map = node.getAttributes();
            if (map != null) {

                // print attribute values
                int length = map.getLength();
                for (int i = 0; i < length; i++) {
                    Node attr = map.item(i);
                    System.out.print(" " + attr.getNodeName() +
                                     "=\"" + attr.getNodeValue() + "\"");
                }
            }

            Node child = node.getFirstChild();
            if (child == null) {
                // no children, so close element and return
                System.out.println("/>");
                return;
            }

            // children, so close current tag
            System.out.println(">");
            while (child != null) {
                // print children recursively
                displayMetadata(child, level + 1);
                child = child.getNextSibling();
            }

            // print close tag of element
            indent(level);
            System.out.println("</" + node.getNodeName() + ">");
        }
        
        private static void print(Metadata metadata, String method)
        {
            System.out.println();
            System.out.println("-------------------------------------------------");
            System.out.print(' ');
            System.out.print(method);
            System.out.println("-------------------------------------------------");
            System.out.println();

            //
            // A Metadata object contains multiple Directory objects
            //
            for (Directory directory : metadata.getDirectories()) {

                //
                // Each Directory stores values in Tag objects
                //
                for (Tag tag : directory.getTags()) {
                    System.out.println(tag);
                }

                //
                // Each Directory may also contain error messages
                //
                for (String error : directory.getErrors()) {
                    System.err.println("ERROR: " + error);
                }
            }
        }
       
        public String saveFileContent(String setFiles) {
    		String lati = "0.0";
    		String longi = "0.0";
    		
    		FileReader textFileReader;
    		String line = null;
    		BufferedReader bufferedReader = null;
    		int readLineNum = 0;
			try {
				textFileReader = new FileReader(setFiles);
				bufferedReader = new BufferedReader(textFileReader);
				while((line = bufferedReader.readLine()) != null) {
					readLineNum ++;
					if(readLineNum == 5){
						if(line != null && !"".equals(line)){
							longi = line;
						}
						
					}else if(readLineNum == 6){
						if(line != null && !"".equals(line)){
							lati = line;
						}
					}
	                System.out.println(line);
	            }
				 bufferedReader.close();
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
    	      
    		String resultData = String.valueOf(longi);
    		resultData += ","+ String.valueOf(lati);
    		return resultData;
    	}
        
        public String saveImageContentFile(File setFiles) {
    		
    		double lati = 0;
    		double longi = 0;
    		String fileDate = "";
    		
    		File file = setFiles;
    		//exif설정
    		IImageMetadata metadata = null;
    		try { metadata = Sanselan.getMetadata(file); }
    		catch(ImageReadException e) { e.printStackTrace(); }
    		catch(IOException e) { e.printStackTrace(); }
    		
    		if(metadata != null){
    			JpegImageMetadata jpegMetadata = (JpegImageMetadata) metadata;
    			if(jpegMetadata != null){	
    				TiffImageMetadata exifMetadata = jpegMetadata.getExif();
    				TiffField field = jpegMetadata.findEXIFValue(TiffTagConstants.TIFF_TAG_DATE_TIME);
    				
    				if(exifMetadata != null) {
    					try {
    						TiffImageMetadata.GPSInfo gpsInfo = exifMetadata.getGPS();
    						if(null != gpsInfo) {
    							
    							
    							longi = gpsInfo.getLongitudeAsDegreesEast();
    							lati = gpsInfo.getLatitudeAsDegreesNorth();
    						}
    					} catch(ImageReadException e) { e.printStackTrace(); }
    				}
    				if(field != null){
    					fileDate = field.getValueDescription();
    				}
    			}	
    		}
    		
    		String resultData = String.valueOf(longi);
    		resultData += ","+ String.valueOf(lati);
    		return resultData;
    	}
}
