package kr.co.turbosoft.util;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import org.apache.commons.codec.binary.Hex;

/*
 * id에 대응하는 session token을 생성하는 과정으로 AES 알고리즘을 적용함
 * 로그인 시 session token을 생성하고 만료시간을 로그인 시간 + 1시간으로 지정함
 * 만료시간 전에 session token으로 api를 요청할 경우 만료 시간을 갱신 (api 요청시간 + 1시간)
 * 만료된 이후 session token으로 요청할 경우 error code를 리턴하며 재 로그인 시 새로운 session token을 생성함  
 */
public class KeyManager {
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
}
