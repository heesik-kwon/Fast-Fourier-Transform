% Added on 2024/07/02 by jihan 
function [fft_out, module2_out] = fft_fixed_stu(fft_mode, fft_in)

 shift = 0;

	din = fft_in; % <2.7> => <3.6>

 fac8_0 = [1, 1, 1, -j];
 %fac8_1 = [1, 1, 1, -j, 1, 0.7071-0.7071j, 1, -0.7071-0.7071j]; % floating
 fac8_1 = [256, 256, 256, -j*256, 256, 181-j*181, 256, -181-j*181]; % fixed <2.8>

 %-----------------------------------------------------------------------------
 % Module 0
 %-----------------------------------------------------------------------------
 % step0_0
 % m1: din - 9bit; bfly00 - 10bit
 bfly00_out0 = din(1:256) + din(257:512);
 bfly00_out1 = din(1:256) - din(257:512);

 bfly00_tmp = [bfly00_out0, bfly00_out1];
    
 for nn=1:512
	bfly00(nn) = bfly00_tmp(nn)*fac8_0(ceil(nn/128));
 end

 % === bfly00 저장 ===
fp = fopen('bfly00_result.txt','w');
for nn = 1:512
    fprintf(fp, '%d %d\n', real(bfly00(nn)), imag(bfly00(nn)));
end
fclose(fp);

 % step0_1
 % m1: bfly00 - 10bit; bfly01_tmp - 11bit; bfly01 - 12bit
 for kk=1:2
  for nn=1:128
	bfly01_tmp((kk-1)*256+nn) = bfly00((kk-1)*256+nn) + bfly00((kk-1)*256+128+nn);
	bfly01_tmp((kk-1)*256+128+nn) = bfly00((kk-1)*256+nn) - bfly00((kk-1)*256+128+nn);
  end
 end

 fp_1=fopen('bfly01.txt','w');
 for nn=1:512
	temp_bfly01(nn) = bfly01_tmp(nn)*fac8_1(ceil(nn/64));
	bfly01(nn) = round(temp_bfly01(nn)/256);
	fprintf(fp_1, 'bfly01_tmp(%d)=%d+j%d, temp_bfly01(%d)=%d+j%d, bfly01(%d)=%d+j%d\n',nn, real(bfly01_tmp(nn)), imag(bfly01_tmp(nn)),nn,real(temp_bfly01(nn)),imag(temp_bfly01(nn)),nn,real(bfly01(nn)),imag(bfly01(nn)));
 end
 fclose(fp_1);

 % === bfly01 저장 ===
fp = fopen('bfly01_result.txt','w');
for nn = 1:512
    fprintf(fp, '%d %d\n', real(bfly01(nn)), imag(bfly01(nn)));
end
fclose(fp);

% figure; % 새로운 그림 창을 엽니다 (선택 사항)
% plot(bfly20); 
% title('bfly00 Result - Magnitude'); % 그래프 제목
% xlabel('Sample Index (nn)');       % x축 레이블
% ylabel('Value');                   % y축 레이블
% grid on;

 % step0_2
 % m1: bfly01 - 12bit; bfly02_tmp - 13bit; pre_bfly02 - 14bit; bfly02 - 11bit
 for kk=1:4
  for nn=1:64
	bfly02_tmp((kk-1)*128+nn) = bfly01((kk-1)*128+nn) + bfly01((kk-1)*128+64+nn);
	bfly02_tmp((kk-1)*128+64+nn) = bfly01((kk-1)*128+nn) - bfly01((kk-1)*128+64+nn);
  end
 end

 for ii=1:512
 	%bfly02_tmp = sat(bfly02_tmp, 13); % Saturatin (13 bit)
 	bfly02_tmp(ii) = sat(bfly02_tmp(ii), 13); % Saturatin (13 bit)
 end

 % Data rearrangement
 K3 = [0, 4, 2, 6, 1, 5, 3, 7];

 for kk=1:8
  for nn=1:64
	flo_twf_m0((kk-1)*64+nn) = exp(-j*2*pi*(nn-1)*(K3(kk))/512);
	twf_m0((kk-1)*64+nn) = round(flo_twf_m0((kk-1)*64+nn)*128); % twf_m0 : <2.7>
  end
 end

 for nn=1:512
	%bfly02(nn) = bfly02_tmp(nn)*twf_m0(nn); % Org 
	pre_bfly02(nn) = bfly02_tmp(nn)*twf_m0(nn); % (14bit(13+1) * 9bit = 23 bit) 
 end

 % CBFP(Convergent Block Floating Point) stage0
 cnt1_re = zeros(1,8);
 cnt1_im = zeros(1,8);
 for ii=1:8
  for jj=1:64
	tmp1_re=mag_detect(real(pre_bfly02(64*(ii-1)+jj)),23);
	tmp1_im=mag_detect(imag(pre_bfly02(64*(ii-1)+jj)),23);
	temp1_re=min_detect(jj,tmp1_re,cnt1_re(ii));
	temp1_im=min_detect(jj,tmp1_im,cnt1_im(ii));
	cnt1_re(ii)=temp1_re;
	cnt1_im(ii)=temp1_im;
  end
 end

 for ii=1:8
  if (cnt1_re(ii)<=cnt1_im(ii))
	cnt1_re(ii)=cnt1_re(ii);
  else
	cnt1_re(ii)=cnt1_im(ii);
  end
 end
		
 for ii=1:8
  if (cnt1_im(ii)<=cnt1_re(ii))
	cnt1_im(ii)=cnt1_im(ii);
  else
	cnt1_im(ii)=cnt1_re(ii);
  end
 end

 for ii=1:8
  for jj=1:64
	index1_re(64*(ii-1)+jj)=cnt1_re(ii);
	index1_im(64*(ii-1)+jj)=cnt1_im(ii);
  end
 end

 for ii=1:8
  for jj=1:64
   if (cnt1_re(ii)>12)
	re_bfly02(64*(ii-1)+jj)=bitshift(bitshift(real(pre_bfly02(64*(ii-1)+jj)),cnt1_re(ii), 'int32'),-12, 'int32');
   else
	re_bfly02(64*(ii-1)+jj)=bitshift(real(pre_bfly02(64*(ii-1)+jj)),(-12+cnt1_re(ii)), 'int32');
   end
  end
 end

 for ii=1:8
  for jj=1:64
   if (cnt1_im(ii)>12)
	im_bfly02(64*(ii-1)+jj)=bitshift(bitshift(imag(pre_bfly02(64*(ii-1)+jj)),cnt1_im(ii), 'int32'),-12, 'int32');
   else
	im_bfly02(64*(ii-1)+jj)=bitshift(imag(pre_bfly02(64*(ii-1)+jj)),(-12+cnt1_im(ii)), 'int32');
   end
  end
 end

 fp_2=fopen('cbfp_0.txt','w');
 for nn=1:512
	bfly02(nn) = re_bfly02(nn) + j*im_bfly02(nn);  
	fprintf(fp_2, 'twf_m0(%d)=%d+j%d, pre_bfly02(%d)=%d+j%d, index1_re(%d)=%d, index1_im(%d)=%d, bfly02(%d)=%d+j%d\n',nn, real(twf_m0(nn)), imag(twf_m0(nn)), nn, real(pre_bfly02(nn)), imag(pre_bfly02(nn)), nn, index1_re(nn), nn, index1_im(nn), nn, real(bfly02(nn)), imag(bfly02(nn)));
 end
 fclose(fp_2);

 % === bfly02 저장 ===
fp = fopen('bfly02_result.txt','w');
for nn = 1:512
    fprintf(fp, '%d %d\n', real(bfly02(nn)), imag(bfly02(nn)));
end
fclose(fp);
 
  fp_5=fopen('re_bfly02.txt','w');
 for nn=1:512
   fprintf(fp_5, '%d\n',real(bfly02(nn)));
 end
 fclose(fp_5);

   fp_5=fopen('im_bfly02.txt','w');
 for nn=1:512
   fprintf(fp_5, '%d\n',imag(bfly02(nn)));
 end
 fclose(fp_5);


 %-----------------------------------------------------------------------------
 % Module 1
 %-----------------------------------------------------------------------------
 % step1_0
 % m1: bfly02 - 11bit; bfly10 - 12bit;

 for kk=1:8
  for nn=1:32
	bfly10_tmp((kk-1)*64+nn) = bfly02((kk-1)*64+nn) + bfly02((kk-1)*64+32+nn);
	bfly10_tmp((kk-1)*64+32+nn) = bfly02((kk-1)*64+nn) - bfly02((kk-1)*64+32+nn);
  end
 end

 for ii=1:512
 	bfly10_tmp(ii) = sat(bfly10_tmp(ii), 12); % Saturatin (12 bit)
 end

 for kk=1:8
  for nn=1:64
	bfly10((kk-1)*64+nn) = bfly10_tmp((kk-1)*64+nn)*fac8_0(ceil(nn/16));
  end
 end

  fp_5=fopen('bfly10_result.txt','w');
 for nn=1:512
   fprintf(fp_5, '%d %d\n',real(bfly10(nn)), imag(bfly10(nn)));
 end
 fclose(fp_5);

 % step1_1
 % m1: bfly10 - 12bit; bfly11_tmp - 13bit; bfly11 - 14bit;
 for kk=1:16
  for nn=1:16
	bfly11_tmp((kk-1)*32+nn) = bfly10((kk-1)*32+nn) + bfly10((kk-1)*32+16+nn);
	bfly11_tmp((kk-1)*32+16+nn) = bfly10((kk-1)*32+nn) - bfly10((kk-1)*32+16+nn);
  end
 end

 for kk=1:8
  for nn=1:64
	temp_bfly11((kk-1)*64+nn) = bfly11_tmp((kk-1)*64+nn)*fac8_1(ceil(nn/8));
	bfly11((kk-1)*64+nn) = round(temp_bfly11((kk-1)*64+nn)/256);
  end
 end

   fp_5=fopen('bfly11_result.txt','w');
 for nn=1:512
   fprintf(fp_5, '%d %d\n',real(bfly11(nn)), imag(bfly11(nn)));
 end
 fclose(fp_5);

 % step1_2
 % m1: bfly11 - 14bit; bfly12_tmp - 15bit; pre_bfly12 - 16bit; bfly12 - 12bit;
 for kk=1:32
  for nn=1:8
	bfly12_tmp((kk-1)*16+nn) = bfly11((kk-1)*16+nn) + bfly11((kk-1)*16+8+nn);
	bfly12_tmp((kk-1)*16+8+nn) = bfly11((kk-1)*16+nn) - bfly11((kk-1)*16+8+nn);
  end
 end

 % Data rearrangement
 K2 = [0, 4, 2, 6, 1, 5, 3, 7];

 for kk=1:8
  for nn=1:8
	flo_twf_m1((kk-1)*8+nn) = exp(-j*2*pi*(nn-1)*(K2(kk))/64);
	twf_m1((kk-1)*8+nn) = round(flo_twf_m1((kk-1)*8+nn)*128); % twf_m0 : <2.7>
  end
 end

 for kk=1:8
  for nn=1:64
	pre_bfly12((kk-1)*64+nn) = bfly12_tmp((kk-1)*64+nn)*twf_m1(nn); % (16bit(15+1) * 9bit = 25 bit) 
  end
 end

 fp = fopen('bfly12_result.txt', 'w');
for nn=1:512
  fprintf(fp, '%d %d\n', real(bfly12_tmp(nn)), imag(bfly12_tmp(nn)));
end
fclose(fp);


 % CBFP(Convergent Block Floating Point) stage1
 cnt2_re = zeros(1,64);
 cnt2_im = zeros(1,64);
 for ii=1:64
  for jj=1:8
	tmp2_re=mag_detect(real(pre_bfly12(8*(ii-1)+jj)),25);
	tmp2_im=mag_detect(imag(pre_bfly12(8*(ii-1)+jj)),25);
	temp2_re=min_detect(jj,tmp2_re,cnt2_re(ii));
	temp2_im=min_detect(jj,tmp2_im,cnt2_im(ii));
	cnt2_re(ii)=temp2_re;
	cnt2_im(ii)=temp2_im;
  end
 end

 %{ 
 for ii=1:64
	X=sprintf('cnt2_re(%d)=%d\n', ii, cnt2_re(ii));
	disp(X);
 end
 %}

 for ii=1:64
  if (cnt2_re(ii)<=cnt2_im(ii))
	cnt2_re(ii)=cnt2_re(ii);
  else
	cnt2_re(ii)=cnt2_im(ii);
  end
 end
		
 for ii=1:64
  if (cnt2_im(ii)<=cnt2_re(ii))
	cnt2_im(ii)=cnt2_im(ii);
  else
	cnt2_im(ii)=cnt2_re(ii);
  end
 end

 for ii=1:64
  for jj=1:8
	index2_re(8*(ii-1)+jj)=cnt2_re(ii);
	index2_im(8*(ii-1)+jj)=cnt2_im(ii);
  end
 end

 
 for ii=1:64
  for jj=1:8
   if (cnt2_re(ii)>13)
	re_bfly12(8*(ii-1)+jj)=bitshift(bitshift(real(pre_bfly12(8*(ii-1)+jj)),cnt2_re(ii), 'int32'),-13, 'int32');
   else
	re_bfly12(8*(ii-1)+jj)=bitshift(real(pre_bfly12(8*(ii-1)+jj)),(-13+cnt2_re(ii)), 'int32');
   end
  end
 end

 for ii=1:64
  for jj=1:8
   if (cnt2_im(ii)>13)
	im_bfly12(8*(ii-1)+jj)=bitshift(bitshift(imag(pre_bfly12(8*(ii-1)+jj)),cnt2_im(ii), 'int32'),-13, 'int32');
   else
	im_bfly12(8*(ii-1)+jj)=bitshift(imag(pre_bfly12(8*(ii-1)+jj)),(-13+cnt2_im(ii)), 'int32');
   end
  end
 end

 fp_4=fopen('cbfp_1.txt','w');
 for nn=1:512
	bfly12(nn) = re_bfly12(nn) + j*im_bfly12(nn);  
	%fprintf(fp_4, 'twf_m1(%d)=%d+j%d, pre_bfly12(%d)=%d+j%d, index2_re(%d)=%d, index2_im(%d)=%d, bfly12(%d)=%d+j%d\n',nn, real(twf_m1(nn)), imag(twf_m1(nn)), nn, real(pre_bfly12(nn)), imag(pre_bfly12(nn)), nn, index2_re(nn), nn, index2_im(nn), nn, real(bfly12(nn)), imag(bfly12(nn)));
	fprintf(fp_4, 'pre_bfly12(%d)=%d+j%d, index2_re(%d)=%d, index2_im(%d)=%d, bfly12(%d)=%d+j%d\n', nn, real(pre_bfly12(nn)), imag(pre_bfly12(nn)), nn, index2_re(nn), nn, index2_im(nn), nn, real(bfly12(nn)), imag(bfly12(nn)));
 end
 fclose(fp_4);

 % === bfly12 저장 ===
fp = fopen('bfly12_result.txt','w');
for nn = 1:512
    fprintf(fp, '%d %d\n', real(bfly12(nn)), imag(bfly12(nn)));
end
fclose(fp);

  fp_5=fopen('re_bfly12.txt','w');
 for nn=1:512
   fprintf(fp_5, '%d\n',real(bfly12(nn)));
 end
 fclose(fp_5);

   fp_5=fopen('im_bfly12.txt','w');
 for nn=1:512
   fprintf(fp_5, '%d\n',imag(bfly12(nn)));
 end
 fclose(fp_5);



 %-----------------------------------------------------------------------------
 % Module 2
 %-----------------------------------------------------------------------------
 % step2_0
 % m1: bfly12 - 12bit; bfly20 - 13bit;
 for kk=1:64
  for nn=1:4
	bfly20_tmp((kk-1)*8+nn) = bfly12((kk-1)*8+nn) + bfly12((kk-1)*8+4+nn);
	bfly20_tmp((kk-1)*8+4+nn) = bfly12((kk-1)*8+nn) - bfly12((kk-1)*8+4+nn);
  end
 end

 for kk=1:64
  for nn=1:8
	bfly20((kk-1)*8+nn) = bfly20_tmp((kk-1)*8+nn)*fac8_0(ceil(nn/2));
  end
 end

fprintf('\nbfly20 results (formatted):\n');
for i = 1:length(bfly20)
    fprintf('%d\n', real(bfly20(i))); % 실수형 출력
    % 만약 bfly00이 복소수라면:
end

% === bfly20 저장 ===
fp = fopen('bfly20_result.txt','w');
for nn = 1:512
    fprintf(fp, '%d %d\n', real(bfly20(nn)), imag(bfly20(nn)));
end
fclose(fp);

 % step2_1
 % m1: bfly20 - 13bit; bfly21_tmp - 14bit; bfly21 - 15bit;
 for kk=1:128
  for nn=1:2
	bfly21_tmp((kk-1)*4+nn) = bfly20((kk-1)*4+nn) + bfly20((kk-1)*4+2+nn);
	bfly21_tmp((kk-1)*4+2+nn) = bfly20((kk-1)*4+nn) - bfly20((kk-1)*4+2+nn);
  end
 end

 for ii=1:512
 	bfly21_tmp(ii) = sat(bfly21_tmp(ii), 14); % Saturatin (14 bit)
 end

 for kk=1:64
  for nn=1:8
	temp_bfly21((kk-1)*8+nn) = bfly21_tmp((kk-1)*8+nn)*fac8_1(nn);
	bfly21((kk-1)*8+nn) = round(temp_bfly21((kk-1)*8+nn)/256);
  end
 end


 fp_5=fopen('bfly21.txt','w');
 for nn=1:512
	fprintf(fp_5, 'bfly21_tmp(%d)=%d+j%d, temp_bfly21(%d)=%d+j%d, bfly21(%d)=%d+j%d\n',nn, real(bfly21_tmp(nn)), imag(bfly21_tmp(nn)),nn, real(temp_bfly21(nn)), imag(temp_bfly21(nn)),nn, real(bfly21(nn)), imag(bfly21(nn)));
 end
 fclose(fp_5);

 % === bfly21 저장 ===
fp = fopen('bfly21_result.txt','w');
for nn = 1:512
    fprintf(fp, '%d %d\n', real(bfly21(nn)), imag(bfly21(nn)));
end
fclose(fp);

 % step2_2
 % m1: bfly21 - 15bit; bfly22_tmp - 16bit; bfly22 - 13bit;
 for kk=1:256
	bfly22_tmp((kk-1)*2+1) = bfly21((kk-1)*2+1) + bfly21((kk-1)*2+2);
	bfly22_tmp((kk-1)*2+2) = bfly21((kk-1)*2+1) - bfly21((kk-1)*2+2);
 end

 for ii=1:512
 	bfly22_tmp(ii) = sat(bfly22_tmp(ii), 16); % Saturatin (16 bit)
 end

 for kk=1:512
	indexsum_re(kk)=index1_re(kk)+index2_re(kk);
	indexsum_im(kk)=index1_im(kk)+index2_im(kk);
 end

 for ii=1:512
  if (indexsum_re(ii)>=23)
	re_bfly22(ii) = 0;
  else
	re_bfly22(ii) = bitshift(real(bfly22_tmp(ii)), (9-indexsum_re(ii)), 'int32'); % 16bit => 13bit <8.5> => <9.4> (FFT)
  end
 end

 for ii=1:512
  if (indexsum_im(ii)>=23)
	im_bfly22(ii) = 0;
  else
	im_bfly22(ii) = bitshift(imag(bfly22_tmp(ii)), (9-indexsum_im(ii)), 'int32'); % 16bit => 13bit <8.5> (FFT)
  end
 end

 for nn=1:512
	bfly22(nn) = re_bfly22(nn) + j*im_bfly22(nn);
 end

   fp_5=fopen('bfly22_result.txt','w');
 for nn=1:512
   fprintf(fp_5, '%d %d\n',real(bfly22(nn)), imag(bfly22(nn)));
 end
 fclose(fp_5);

 %bfly22 = bfly22_tmp;

 %-----------------------------------------------------------------------------
 % Index 
 %-----------------------------------------------------------------------------
 fp=fopen('fxd_reorder_index.txt','w');
 for jj=1:512
	%kk = bitget(jj-1,9)*(2^0) + bitget(jj-1,8)*(2^1) + bitget(jj-1,7)*(2^2) + bitget(jj-1,6)*(2^3) + bitget(jj-1,5)*(2^4) + bitget(jj-1,4)*(2^5) + bitget(jj-1,3)*(2^6) + bitget(jj-1,2)*(2^7) + bitget(jj-1,1)*(2^8);
	kk = bitget(jj-1,9)*1 + bitget(jj-1,8)*2 + bitget(jj-1,7)*4 + bitget(jj-1,6)*8 + bitget(jj-1,5)*16 + bitget(jj-1,4)*32 + bitget(jj-1,3)*64 + bitget(jj-1,2)*128 + bitget(jj-1,1)*256;
	dout(kk+1) = bfly22(jj); % With reorder
	%fprintf(fp, 'jj=%d, kk=%d, dout(%d)=%d+j%d, indexsum=%d\n',jj, kk,(kk+1),real(dout(kk+1)),imag(dout(kk+1)),indexsum_re(kk+1));
 end
 fclose(fp);

	fft_out = dout;
	module2_out = bfly22;
 

 
% -----------------------------------------------------------------------------
% Export ROM data for Verilog
% -----------------------------------------------------------------------------

% [1] 디렉토리 생성 (없으면)
if ~exist('output', 'dir')
    mkdir('output');
end

% [2] fac8_0 출력
fp0 = fopen('output/fac8_0.txt', 'w');
for i = 1:length(fac8_0)
    fprintf(fp0, '%d %d\n', real(fac8_0(i)), imag(fac8_0(i)));
end
fclose(fp0);


fp10 = fopen('output/bfly12.txt', 'w');
for i = 1:512
    fprintf(fp0, '%d %d\n', real(bfly12(i)), imag(bfly12(i)));
end
fclose(fp10);

fp11 = fopen('output/bfly20.txt', 'w');
for i = 1:512
    fprintf(fp0, '%d %d\n', real(bfly20(i)), imag(bfly20(i)));
end
fclose(fp11);

% [3] fac8_1 출력
fp1 = fopen('output/fac8_1.txt', 'w');
for i = 1:length(fac8_1)
    fprintf(fp1, '%d %d\n', real(fac8_1(i)), imag(fac8_1(i)));
end
fclose(fp1);

% [4] twf_m0 출력
fp2 = fopen('output/twf_m0.txt', 'w');
for i = 1:length(twf_m0)
    fprintf(fp2, '%d %d\n', real(twf_m0(i)), imag(twf_m0(i)));
end
fclose(fp2);

% [5] twf_m1 출력
fp3 = fopen('output/twf_m1.txt', 'w');
for i = 1:length(twf_m1)
    fprintf(fp3, '%d %d\n', real(twf_m1(i)), imag(twf_m1(i)));
end
fclose(fp3);

% [6] index2_re 출력
fp4 = fopen('output/index2_re.txt', 'w');
for i = 1:length(index2_re)
    fprintf(fp4, '%d\n', index2_re(i));
end
fclose(fp4);

% [7] index2_im 출력
fp5 = fopen('output/index2_im.txt', 'w');
for i = 1:length(index2_im)
    fprintf(fp5, '%d\n', index2_im(i));
end
fclose(fp5);

% [8] indexsum_re 출력
fp6 = fopen('output/indexsum_re.txt', 'w');
for i = 1:length(indexsum_re)
    fprintf(fp6, '%d\n', indexsum_re(i));
end
fclose(fp6);

% [9] indexsum_im 출력
fp7 = fopen('output/indexsum_im.txt', 'w');
for i = 1:length(indexsum_im)
    fprintf(fp7, '%d\n', indexsum_im(i));
end
fclose(fp7);

end
