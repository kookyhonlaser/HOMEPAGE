쿠키혼레이저 홈페이지 SEO 업데이트 - 2026-06-29

변경 내용
---------
1. index.html 메인 SEO 수정
   - title / description / keywords / canonical / OG 태그 추가
   - LocalBusiness 구조화 데이터(JSON-LD) 삽입
   - 메인 문구에 "레이저 마킹기", "파이버·UV·CO2" 키워드 반영
   - 검색엔진용 제품 상세 페이지 바로가기 섹션 추가
   - 네이버 블로그 사례 연결 영역을 제품 상세 페이지와 연결되도록 개선
   - footer에 주요 제품 상세 페이지 링크 추가
   - index.html#products, index.html#contact 같은 해시 링크 접속 시 해당 섹션이 열리도록 JS 보완

2. 제품별 검색 노출용 독립 상세 페이지 5개 추가
   - laser-marking-machine.html
   - fiber-laser-marking-machine.html
   - uv-laser-marking-machine.html
   - co2-laser-marking-machine.html
   - laser-marking-automation.html

3. 각 상세 페이지 포함 항목
   - 제품 사진
   - 기본 사양표
   - 적용 소재
   - 샘플 마킹/응용 이미지
   - FAQ 구조화 데이터
   - 상담문의 및 네이버 블로그 사례 연결

4. 검색엔진 파일 추가
   - sitemap.xml
   - robots.txt

5. 관리자 페이지 검색 노출 방지
   - admin.html, inquiry-detail.html에 noindex 처리

업로드 방법
---------
- 이 ZIP의 HOMEPAGE-main 폴더 안 파일 전체를 기존 GitHub Pages 저장소에 덮어쓰기 업로드하세요.
- 업로드 후 https://www.kooky.co.kr/sitemap.xml 과 https://www.kooky.co.kr/robots.txt 가 열리는지 확인하세요.
- 구글 Search Console과 네이버 서치어드바이저에서 sitemap.xml을 제출하세요.

주의 사항
---------
- 구글 Search Console / 네이버 서치어드바이저 등록은 사이트 소유자 인증이 필요하므로 코드만으로 자동 완료할 수 없습니다.
- 인증 코드가 발급되면 index.html head에 추가하거나 HTML 인증 파일을 루트에 업로드해야 합니다.
- 네이버 블로그 사례 글은 현재 기존 소스에 있던 블로그 URL을 유지했습니다. 실제 사례 글이 늘어나면 각 제품 상세 페이지에서 추가 연결하면 좋습니다.
