-- Seed 80 test respondents with answers skewed toward Agree (4) / Strongly Agree (5)
-- Run this in Supabase SQL Editor after setup.sql has been executed

do $$
declare
  v_id uuid;
  v_submitted_at timestamptz;
  v_name text;
  v_age int;
  v_sex text;
  v_user_type text;
  v_answers jsonb;
  v_comments text;
  v_consent_date timestamptz;
  v_answer_weights int[];
  v_item_val int;
  v_items jsonb;
  v_names text[] := array[
    'Juan Dela Cruz', 'Maria Santos', 'Pedro Reyes', 'Ana Gonzales',
    'Jose Garcia', 'Luisa Fernandez', 'Carlos Lopez', 'Sofia Martinez',
    'Miguel Torres', 'Isabella Ramos', 'Antonio Castillo', 'Angela Rivera',
    'Manuel Flores', 'Carmen Diaz', 'Ramon Bautista', 'Teresa Morales',
    'Francisco Jimenez', 'Rosa Navarro', 'Eduardo Vargas', 'Luz Mendoza',
    'Fernando Ortiz', 'Elena Guerrero', 'Roberto Santiago', 'Gloria Paredes',
    'Alberto Cruz', 'Dolores Alvarez', 'Enrique Romero', 'Ofelia Castro',
    'Ricardo Delos Santos', 'Nelia Aquino', 'Gregorio Villanueva', 'Leticia Reyes',
    'Santiago Hernandez', 'Milagros Tan', 'Victor Manuel', 'Corazon Gomez',
    'Rafael Mendoza', 'Natividad Cruz', 'Luis Antonio', 'Fe Salvador',
    'Oscar Fernandez', 'Aurora Quinto', 'Jaime Villar', 'Luzviminda Dimagiba',
    'Dante Garcia', 'Perlita Sison', 'Rogelio Ramos', 'Bella Flores',
    'Cesar Mercado', 'Lilian Castro', 'Dominador Santos', 'Eva Lopez',
    'Fidel Torres', 'Nenita Jimenez', 'Gilbert Reyes', 'Zenaida Cruz',
    'Hernando Gomez', 'Yolanda Villanueva', 'Isagani Bautista', 'Wilma Ortiz',
    'Joaquin Salvador', 'Ursula Fernandez', 'Kris Bernal', 'Querubin Garcia',
    'Levi Mendoza', 'Imelda Santos', 'Mario Lopez', 'Nilda Ramos',
    'Narciso Reyes', 'Olivia Torres', 'Pablo Cruz', 'Princess Villar',
    'Quirino Hernandez', 'Rita Flores', 'Rudy Castro', 'Socorro Gomez',
    'Tomas Rivera', 'Violeta Bautista', 'Uriel Garcia', 'Winnie Santos',
    'Venancio Reyes', 'Xenia Lopez', 'Wilfredo Cruz', 'Yna Ramos',
    'Zosimo Torres', 'Agnes Villanueva'
  ];
  v_types text[] := array['Student', 'Faculty / Teacher', 'Parent / Guardian', 'School Administrator / Staff', 'IT Expert'];
begin
  for i in 1..80 loop
    v_id := gen_random_uuid();
    v_submitted_at := now() - (random() * interval '30 days');
    v_name := v_names[i];
    v_age := 18 + floor(random() * 43)::int;  -- 18 to 60
    v_sex := case when random() < 0.5 then 'Male' else 'Female' end;
    v_user_type := v_types[1 + floor(random() * 5)::int];

    -- Generate answers with ~70% probability of 4 or 5
    v_items := '{}'::jsonb;
    for k in 1..30 loop
      v_answer_weights := case
        when random() < 0.35 then array[5]      -- 35% Strongly Agree
        when random() < 0.70 then array[4]      -- 35% Agree
        else array[1,2,3,4,5]                   -- 30% spread across all
      end;
      v_item_val := v_answer_weights[1 + floor(random() * array_length(v_answer_weights, 1))::int];
      v_items := jsonb_set(v_items, array[k::text], to_jsonb(v_item_val));
    end loop;
    v_answers := v_items;

    v_comments := case
      when random() < 0.3 then 'The system is helpful for our school needs.'
      when random() < 0.5 then 'Very user-friendly and easy to navigate.'
      when random() < 0.7 then 'I recommend this to other schools.'
      when random() < 0.85 then ''
      else ''
    end;

    v_consent_date := v_submitted_at;

    insert into responses (
      id, submitted_at, respondent_name, respondent_age, respondent_sex,
      respondent_user_type, consent_given, consent_date, answers, comments
    ) values (
      v_id, v_submitted_at, v_name, v_age, v_sex,
      v_user_type, true, v_consent_date, v_answers, v_comments
    );
  end loop;
end $$;

-- Verify
select count(*) as total_responses from responses;
