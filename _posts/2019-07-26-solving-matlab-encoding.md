---
layout:     post
title:      Solve MATLAB Encoding Problem using UTF-8
subtitle:   UTF-8 unifies the world
date:       2019-07-26
author:     Rui Li
excerpt: Recently, it is time for me to read & use them again. However, when I re-open those scripts in MATLAB, all the comments (previously written in Chinese) becomes garbled characters.
catalog: true
tags:
    - MATLAB
    - encoding
---

Previously I wrote some MATLAB scripts with comments in Chinese. At that time I used Windows 10 with China/simplified Chinese region/language setting. After finishing that work, I pushed those codes to my Github repository for a later use.

Recently, it is time for me to read & use them again. However, when I re-open those scripts in MATLAB, all the comments (previously written in Chinese) becomes garbled characters. It is really annoying without these comments, because I named those scripts like `script_001.m`, `script_002.m`, `script_003.m`... Without the comments, I have to read the source codes line by line to regain knowledge about what the differences between them are.

After some searching work, I found that I switched to the English version of Windows 10, where the default encoding character set is different from the simplified Chinese version. But for some reason, I cannot change back to the previous version. So I tried to find a solution for restoring the comments in my current system settings.

The first thing is to figure out what encoding the previous MATLAB used for my codes. With VS Code, it is really an easy work. Just open the `.m` script with VS Code, at the bottom-right corner, click on the current encoding name (e.g. UTF-8), then a drop-down menu will appear asking you to reopen the file with another encoding. After clicking on that, VS Code will guess what is the best suitable option for your file.  For my case, the original encoding is GB2312. Now I need to save it with UTF-8. Again you simply click on the encoding name and select "Save with Encoding" and then choose UTF-8. Now the scripts should be saved in UTF-8 encoding.

![post-matlab-encoding-01](https://raw.githubusercontent.com/raysworld/raysworld.github.io/master/img/post-matlab-encoding-01.png)

However, MATLAB still does not recognise the characters after the conversion. After some further search [1], I noticed that MATLAB does not use UTF-8 as default encoding (instead, windows-1252). Now the problem becomes how to change the MATLAB default encoding to UTF-8. The answer is also in that page. The steps are listed as below:

1. Navigate to `(MATLAB_installation_path)\(MATLAB_version)\bin`. There will be a `lcdata.xml` in it. If you use R2017 or later, there will be also a `lcdata_utf8.xml` in the folder. In that case, rename the `lcdata.xml` to `lcdata.xml.bak`, duplicate `lcdata_utf8.xml` and rename one of them to `lcdata.xml`.

2. Open `lcdata.xml`. Search and find the encoding you are using. For my case, it is "windows-1252". You may find it in MATLAB by typing `feature('DefaultCharacterSet')`.

3. Comment the following tag:

   ```xml
   <encoding name="windows-1252" jvm_encoding="Cp1252">
   	<encoding_alias name="1252"/>
   </encoding>
   ```

   For `.xml` files, after commenting it should look like this:

   ```xml
   <!-- <encoding name="windows-1252" jvm_encoding="Cp1252">
   	<encoding_alias name="1252"/>
   </encoding> -->
   ```

4. Search and find the tag for UTF-8, change it from

   ```xml
   <encoding name="UTF-8">
       <encoding_alias name="utf8"/>
   </encoding>
   ```

   to

   ```xml
   <encoding name="UTF-8">
       <encoding_alias name="utf8"/>
       <encoding_alias name="windows-1252"/>
   </encoding>
   ```

Now MATLAB should use UTF-8 as its default encoding. 



##### References

[1] https://ww2.mathworks.cn/matlabcentral/answers/280988-how-do-i-get-my-matlab-editor-to-read-utf-8-characters-utf-8-characters-in-blank-squares-in-editors

