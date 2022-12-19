'''
Project-->which project use this AI Model Version
Date-->Send model to algorithm by Email：xxxx-xx-xx(year-month-day), for example: 2021-01-01
Version--> V1.0.0.0(1.0.0 represent AI model version, the end zero(0) represent Close Data Collection, if one(1) represent Open Data Collection)

Date-->if use previous model, i will note recall, for example: 2021-01-02-Recall-2021-01-01)
Version-->V1.0.0.0

"You just need to pay attention to whether the version number is consistent with what I sent !"
'''

Project: S1_AI_Model
Date: 2021-06-24
Version: V1.2.6.0

1.Update instructions(/robot/AI/README.txt)
(1)开启地毯的地板识别通道，同时通过高精度的检测+分类模式触发地毯的地板识别通道的时间序列机制，提升地板通道的地毯识别精度。
(2)修改AI识别图像的时间戳更新问题

2.Update file MD5(/robot/AI)
(1)README.txt(this file will change after rewrite README.txt MD5)
(2)b3c5eca8174d64d6ffd4fb6c0f79f55b  ai_config.txt
(3)b1bc2e35c8d8ccab1b9d22c98200cc1b  ai_log_config.ini
(4)1538f719e47f47e0069830c087500204  all_class_model.rknn
(5)e0de0bfa967ca01e352bfaab680ba491  all_class_model_bd.rknn
(6)f19ea83f6ceb08ada9af5ca7fa9bc9f7  class_min_score.txt
(7)9a7aea7d45a871eeafc0b7c62386888b  yolo4_tiny.rknn

3.Ai-server(/robot/app/bin)
(1)5b46d04e1b1fe97d6ac5ca7176e2d506  Ai-server(Note:Close Data Collection)
(2)5ac3539421aa37953df5a23eb5766f24  Ai-server(Note:Open Data Collection)

