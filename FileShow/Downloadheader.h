//
//  Downloadheader.h
//  QSPDownLoad_Demo
//
//  Created by 张源远 on 2018/8/6.
//  Copyright © 2018年 PowesunHolding. All rights reserved.
//

#ifndef Downloadheader_h
#define Downloadheader_h


#define QSPDownloadTool_Document_Path                   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]

#define QSPDownloadTool_DownloadDataDocument_Path       [QSPDownloadTool_Document_Path stringByAppendingPathComponent:@"QSPDownloadTool_DownloadDataDocument_Path"]

#define QSPDownloadTool_DownloadSources_Path            [QSPDownloadTool_Document_Path stringByAppendingPathComponent:@"QSPDownloadTool_downloadSources.data"]

#define QSPDownloadTool_OffLineStyle_Key                @"QSPDownloadTool_OffLineStyle_Key"
#define QSPDownloadTool_OffLine_Key                     @"QSPDownloadTool_OffLine_Key"


#define QSPDownloadTool_DownloadFinishedSources_Path        [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"QSPDownloadTool_DownloadFinishedSources.data"]

#define QSPDownloadTool_Limit                           1024.0

#endif /* Downloadheader_h */
