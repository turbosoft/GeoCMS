package kr.co.turbosoft.geocms.util;

import java.io.UnsupportedEncodingException;
import java.security.GeneralSecurityException;
import java.security.Key;
import java.security.NoSuchAlgorithmException;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import javax.servlet.http.HttpServletRequest;

import org.apache.commons.codec.binary.Hex;
import org.apache.commons.codec.binary.Base64;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

/*
 * id�� �����ϴ� session token�� �����ϴ� �������� AES �˰����� ������
 * �α��� �� session token�� �����ϰ� ����ð��� �α��� �ð� + 1�ð����� ������
 * ����ð� ���� session token���� api�� ��û�� ��� ���� �ð��� ���� (api ��û�ð� + 1�ð�)
 * ����� ���� session token���� ��û�� ��� error code�� �����ϸ� �� �α��� �� ���ο� session token�� ������  
 */
public class KeyManager {
	private String keySpec = "GLGMHKJKKBGBMNAIOGLFKKIGAIMLDDEJ";
	
	public String genKey(String id) throws Exception {
		//generate 128 bit secret key
		KeyGenerator kgen = KeyGenerator.getInstance("AES");
		kgen.init(128);
		SecretKey skey = kgen.generateKey();
		
		//encode
		SecretKeySpec skeySpec = new SecretKeySpec(skey.getEncoded(), "AES");
		Cipher cipher = Cipher.getInstance("AES");
		cipher.init(Cipher.ENCRYPT_MODE, skeySpec);
		byte[] encrypted = cipher.doFinal(id.getBytes());
		String encString = Hex.encodeHexString(encrypted);
		System.out.println(encString);
		return encString;
	}
	
	/** 
	 * * 16�ڸ��� Ű���� �Է��Ͽ� ��ü�� �����Ѵ�. 
	 * * @param key ��/��ȣȭ�� ���� Ű�� 
	 * * @throws UnsupportedEncodingException Ű���� ���̰� 16������ ��� �߻� 
	 * */ 
//	public void AES256Util(String key) throws UnsupportedEncodingException { 
//		this.iv = key.substring(0, 16);
//		byte[] keyBytes = new byte[16];
//		byte[] b = key.getBytes("UTF-8");
//		int len = b.length;
//		if(len > keyBytes.length){
//			len = keyBytes.length;
//		} 
//		System.arraycopy(b, 0, keyBytes, 0, len);
//		SecretKeySpec keySpec = new SecretKeySpec(keyBytes, "AES");
//		this.keySpec = keySpec;
//	} 
	
	/** 
	 * * AES256 ���� ��ȣȭ �Ѵ�. 
	 * * @param str ��ȣȭ�� ���ڿ�
	 *  * @return 
	 *  * @throws NoSuchAlgorithmException 
	 *  * @throws GeneralSecurityException 
	 *  * @throws UnsupportedEncodingException 
	 *  */
	// 1byte�� 4bit�� ©�� ���ڿ��� �ٲٴ� �Լ�
	private String bitEncodiong(byte[] data) {
		StringBuffer resultStr = new StringBuffer();
		for (byte b : data)
		{
			resultStr.append((char)(65 + ((b >> 4) & 0x0f)));
			resultStr.append((char)(65 + (b & 0x0f)));
		}
		
		return resultStr.toString();
	}
	
	// 1byte�� 4bit�� ©�� ���ڿ��� �ٲ� �����͸� �ٽ� byte�� �ٲ��ִ� �Լ�
	private byte[] bitDecodiong(char[] data) {
		int i =0, j=0, dataSize=data.length;
		byte [] resultByte = null;
		byte temp1 = 0;
		byte temp2 = 0;

		if(dataSize < Integer.MAX_VALUE)
		{
			if(dataSize != 0)
			{
				resultByte = new byte[dataSize/2];
			}
		}

		for (char b : data)
		{
			if(i<dataSize)
			{
				if((i % 2) == 0)
				{
					temp1 = (byte) ((((byte)b)-65) << 4);
				}
				if((i % 2) == 1)
				{
					temp2 = (byte) (((byte)b)-65);
					resultByte[j] = (byte) (temp1 | temp2);
					temp1 = 0;
					temp2 = 0;
					j++;
				}
			}
			i++;
		}

		return resultByte;
	}
		
	public String encrypt(String str) throws NoSuchAlgorithmException, GeneralSecurityException, UnsupportedEncodingException{
//		KeyGenerator kgen = KeyGenerator.getInstance("AES");
//		kgen.init(128);
//		SecretKey skey = kgen.generateKey();
//		String secretStr = bitEncodiong(skey.getEncoded());
//		this.keySpec = secretStr;
//		SecretKeySpec skeySpec = new SecretKeySpec(skey.getEncoded(), "AES");
		    
//		Cipher cipher = Cipher.getInstance("AES");
//		cipher.init(Cipher.ENCRYPT_MODE, skeySpec);
//		byte[] encrypted = cipher.doFinal(str.getBytes());
//		String encString = new String(Base64.encodeBase64(encrypted));
//		System.out.println(secretStr + "/n"+encString);
//		return encString;
		
		Cipher cipher;
		String encryptedString;
		byte[] encryptText = null;
		byte[] raw = null;
		
		SecretKeySpec skeySpec;
		raw = bitDecodiong(keySpec.toCharArray());
		skeySpec = new SecretKeySpec(raw, "AES");
		
//		SecretKeySpec skeySpec = new SecretKeySpec(skey.getEncoded(), "AES");
		cipher = Cipher.getInstance("AES");
		cipher.init(Cipher.ENCRYPT_MODE, skeySpec);
		byte[] encrypted = cipher.doFinal(str.getBytes());
		String encString = bitEncodiong(encrypted);
		return encString;
		
//		encryptText = bitDecodiong(str.toCharArray());
//		encryptedString = new String(cipher.doFinal(encryptText));
//		return encryptedString;
		
//		Cipher c = Cipher.getInstance("AES/CBC/PKCS5Padding");
//		c.init(Cipher.ENCRYPT_MODE, keySpec, new IvParameterSpec(iv.getBytes()));
//		byte[] encrypted = c.doFinal(str.getBytes("UTF-8"));
//		String enStr = new String(Base64.encodeBase64(encrypted));
//		return enStr;
	} 
	
	/** 
	 * * AES256���� ��ȣȭ�� txt �� ��ȣȭ�Ѵ�. 
	 * * @param str ��ȣȭ�� ���ڿ�
	 *  * @return 
	 *  * @throws NoSuchAlgorithmException 
	 *  * @throws GeneralSecurityException 
	 *  * @throws UnsupportedEncodingException 
	 *  */ 
	public String decrypt(String str) throws NoSuchAlgorithmException, GeneralSecurityException, UnsupportedEncodingException {
		Cipher cipher;
		String encryptedString;
		byte[] encryptText = null;
		byte[] raw = null;
		
		SecretKeySpec skeySpec;
		raw = bitDecodiong(keySpec.toCharArray());
		skeySpec = new SecretKeySpec(raw, "AES");
		
		cipher = Cipher.getInstance("AES");
		cipher.init(Cipher.DECRYPT_MODE, skeySpec);
		encryptText = bitDecodiong(str.toCharArray());
		encryptedString = new String(cipher.doFinal(encryptText));
		return encryptedString;
		
//		Cipher cipher = Cipher.getInstance("AES");
//		cipher.init(Cipher.DECRYPT_MODE, keySpec);
//		byte[] decrypted = cipher.doFinal(str.getBytes());
//		String decString = new String(Base64.decodeBase64(decrypted));
//		System.out.println(decString);
//		return decString;
		
//		Cipher c = Cipher.getInstance("AES/CBC/PKCS5Padding");
//		c.init(Cipher.DECRYPT_MODE, keySpec, new IvParameterSpec(iv.getBytes()));
//		byte[] byteStr = Base64.decodeBase64(str.getBytes());
//		return new String(c.doFinal(byteStr), "UTF-8");
	}
	
}
