media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":0[crop:(0,0)/224x1557]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":0[fmt:SBGGR12_1X12/224x1557]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":2[crop:(0,0)/224x1557]'
media-ctl -d /dev/media0 --set-v4l2 '"rkisp1-isp-subdev":2[fmt:SBGGR12_1X12/224x1557]'

v4l2-ctl -d /dev/video0 --set-selection=target=crop,top=0,left=0,width=224,height=1557 --set-fmt-video=width=224,height=1557,pixelformat=BG12 --stream-mmap=3 --stream-poll &
