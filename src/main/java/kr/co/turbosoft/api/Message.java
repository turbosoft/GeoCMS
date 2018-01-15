package kr.co.turbosoft.api;

import kr.co.turbosoft.dao.DataDao;
import kr.co.turbosoft.dao.UserDao;

public class Message {
	public static String code100 = "정상처리 되었습니다.";
	public static String code101 = "가입할 수 있는 아이디입니다.";
	public static String code102 = "이미 가입된 아이디입니다.";
	public static String code103 = "가입할 수 있는 이메일입니다.";
	public static String code104 = "이미 가입된 이메일입니다.";
	public static String code105 = "회원 정보가 존재하지 않습니다.";
	public static String code106 = "이미 가입된 아이디와 이메일 입니다.";
	public static String code107 = "회원가입이 완료 되었습니다.";
	public static String code200 = "데이터가 존재하지 않습니다.";
	public static String code201 = "비밀번호가 다릅니다.";
	
	public static String code202 = "Session Token 처리 오류입니다.";
	public static String code203 = "Session Token이 만료되었습니다.";
	public static String code204 = "Session Token 정보가 없습니다.";
	public static String code205 = "Session Token 정보와 로그인 정보가 일치하지 않습니다.";
	
	public static String code300 = "데이터베이스 처리 오류입니다.";
	public static String code400 = "파일 처리 오류입니다.";
	public static String code500 = "관리자만 사용가능한 메뉴입니다.";
	public static String code600 = "조건에 맞지 않는 데이터가 있습니다.";
	public static String code700 = "해당 데이터에 대한 권한이 없습니다.";
	
	
	public static String code800 = "시스템 오류입니다. 오류메시지를 확인해 주세요.";
	public static String code900 = "하위 버전 사용자입니다. 앱을 업데이트 받으시기 바랍니다.";
	
	//등록된 의사 면허 확인 message
	public static String code801 = "이미 등록된 의사면허입니다.";
	public static String code802 = "예약일이 지정되지 않았습니다.";
	public static String code803 = "예약일이 지났습니다.";
	
	public static String code901 = "인증되지 않은 사용자입니다.";
	
	static DataDao dataDao = null;
	static UserDao userDao = null;
}
