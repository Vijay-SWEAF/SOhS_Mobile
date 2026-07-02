export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type Database = {
  public: {
    Tables: {
      app_daily_questions: {
        Row: {
          id: string;
          question_id: string | null;
          active_date: string;
          day_number: number;
          kind: string;
          question_text: string;
          context: string | null;
          options: Json;
          think: Json;
          twist: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          question_id?: string | null;
          active_date: string;
          day_number: number;
          kind?: string;
          question_text: string;
          context?: string | null;
          options: Json;
          think: Json;
          twist?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          question_id?: string | null;
          active_date?: string;
          day_number?: number;
          kind?: string;
          question_text?: string;
          context?: string | null;
          options?: Json;
          think?: Json;
          twist?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "app_daily_questions_question_id_fkey";
            columns: ["question_id"];
            isOneToOne: false;
            referencedRelation: "human_questions";
            referencedColumns: ["id"];
          },
        ];
      };
      app_vote_counts: {
        Row: {
          question_id: string;
          option0_count: number;
          option1_count: number;
          updated_at: string;
        };
        Insert: {
          question_id: string;
          option0_count?: number;
          option1_count?: number;
          updated_at?: string;
        };
        Update: {
          question_id?: string;
          option0_count?: number;
          option1_count?: number;
          updated_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "app_vote_counts_question_id_fkey";
            columns: ["question_id"];
            isOneToOne: true;
            referencedRelation: "app_daily_questions";
            referencedColumns: ["id"];
          },
        ];
      };
      app_vote_country_counts: {
        Row: {
          question_id: string;
          country_code: string;
          option0_count: number;
          option1_count: number;
        };
        Insert: {
          question_id: string;
          country_code: string;
          option0_count?: number;
          option1_count?: number;
        };
        Update: {
          question_id?: string;
          country_code?: string;
          option0_count?: number;
          option1_count?: number;
        };
        Relationships: [
          {
            foreignKeyName: "app_vote_country_counts_question_id_fkey";
            columns: ["question_id"];
            isOneToOne: false;
            referencedRelation: "app_daily_questions";
            referencedColumns: ["id"];
          },
        ];
      };
      app_votes: {
        Row: {
          id: string;
          question_id: string;
          device_id: string;
          option_index: number;
          country_code: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          question_id: string;
          device_id: string;
          option_index: number;
          country_code?: string | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          question_id?: string;
          device_id?: string;
          option_index?: number;
          country_code?: string | null;
          created_at?: string;
        };
        Relationships: [
          {
            foreignKeyName: "app_votes_question_id_fkey";
            columns: ["question_id"];
            isOneToOne: false;
            referencedRelation: "app_daily_questions";
            referencedColumns: ["id"];
          },
        ];
      };
    };
    Views: Record<string, never>;
    Functions: {
      cast_vote: {
        Args: {
          p_question_id: string;
          p_device_id: string;
          p_option_index: number;
          p_country_code?: string | null;
        };
        Returns: Json;
      };
    };
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};
