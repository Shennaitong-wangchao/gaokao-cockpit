package com.gaokao.cockpit.di

import android.content.Context
import androidx.room.Room
import com.gaokao.cockpit.data.local.AppDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "gaokao_cockpit.db"
        ).build()
    }

    @Provides
    fun provideStudyTaskDao(db: AppDatabase) = db.studyTaskDao()

    @Provides
    fun provideDayPlanDao(db: AppDatabase) = db.dayPlanDao()

    @Provides
    fun provideFocusSessionDao(db: AppDatabase) = db.focusSessionDao()

    @Provides
    fun provideMistakeRecordDao(db: AppDatabase) = db.mistakeRecordDao()

    @Provides
    fun provideDailyReviewDao(db: AppDatabase) = db.dailyReviewDao()

    @Provides
    fun provideWeeklyReviewDao(db: AppDatabase) = db.weeklyReviewDao()

    @Provides
    fun providePromptTemplateDao(db: AppDatabase) = db.promptTemplateDao()

    @Provides
    fun provideResourceItemDao(db: AppDatabase) = db.resourceItemDao()
}
